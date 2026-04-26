package com.doitdo.global.client;

import com.doitdo.global.client.dto.AppleUserInfo;
import com.doitdo.global.exception.AuthErrorCode;
import com.doitdo.global.exception.CustomException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Header;
import io.jsonwebtoken.JwsHeader;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.Locator;
import io.jsonwebtoken.security.Jwk;
import io.jsonwebtoken.security.Jwks;
import java.security.Key;
import java.security.PublicKey;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

/**
 * Apple Sign-In 으로 받은 identityToken(JWT) 을 검증한다.
 *
 * <p>검증 절차:
 * <ol>
 *   <li>JWT header 의 {@code kid} 로 Apple JWKS({@value #APPLE_JWKS_URL}) 에서 매칭되는 공개키 조회</li>
 *   <li>RS256 서명 검증 + {@code iss=https://appleid.apple.com} + {@code aud=<bundle id>} + {@code exp} 검증</li>
 *   <li>{@code sub}, {@code email}, {@code email_verified} 추출</li>
 * </ol>
 *
 * <p>JWKS 는 {@link ConcurrentHashMap} 으로 캐시하며, kid 미스시 1회 강제 새로고침한다
 * (Apple 이 키를 주기적으로 롤오버하므로). 캐시 갱신은 lock 으로 직렬화해서 thundering herd 방지.
 *
 * <p>{@code audience} 는 iOS 네이티브 로그인 기준 앱 Bundle Identifier 와 일치해야 한다.
 * Web/Service ID 등 추가 audience 가 생기면 콤마 구분 다중 값 지원으로 확장 필요.
 */
@Slf4j
@Component
public class AppleIdTokenVerifierService {

	private static final String APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys";
	private static final String APPLE_ISSUER = "https://appleid.apple.com";

	private final String clientId;
	private final RestTemplate restTemplate;
	private final ObjectMapper objectMapper = new ObjectMapper();
	private final Map<String, PublicKey> publicKeyCache = new ConcurrentHashMap<>();
	private final Object refreshLock = new Object();

	public AppleIdTokenVerifierService(
			@Value("${apple.oauth.client-id:}") String clientId,
			RestTemplate restTemplate
	) {
		this.clientId = clientId;
		this.restTemplate = restTemplate;
	}

	public AppleUserInfo verify(String identityToken) {
		if (clientId == null || clientId.isBlank()) {
			log.error("apple.oauth.client-id 설정이 비어 있어 Apple 로그인을 처리할 수 없습니다.");
			throw new CustomException(AuthErrorCode.A03_004);
		}

		try {
			Claims claims = Jwts.parser()
					.keyLocator(appleKeyLocator())
					.requireIssuer(APPLE_ISSUER)
					.requireAudience(clientId)
					.build()
					.parseSignedClaims(identityToken)
					.getPayload();

			String sub = claims.getSubject();
			String email = claims.get("email", String.class);
			Boolean emailVerified = readBooleanClaim(claims, "email_verified");

			if (sub == null || sub.isBlank()) {
				log.warn("Apple identityToken 에 sub 클레임이 없음");
				throw new CustomException(AuthErrorCode.A03_001);
			}
			return new AppleUserInfo(sub, email, emailVerified);
		} catch (JwtException e) {
			log.warn("Apple identityToken 검증 실패: {}", e.getMessage());
			throw new CustomException(AuthErrorCode.A03_001);
		} catch (IllegalArgumentException e) {
			log.warn("Apple identityToken 형식 오류: {}", e.getMessage());
			throw new CustomException(AuthErrorCode.A03_001);
		}
	}

	/**
	 * Apple 의 {@code email_verified} 클레임은 boolean 또는 문자열("true"/"false") 로 올 수 있어
	 * {@link Claims#get(String, Class)} 로 직접 Boolean 캐스팅하면 ClassCastException 위험이 있다.
	 */
	private Boolean readBooleanClaim(Claims claims, String key) {
		Object raw = claims.get(key);
		if (raw == null) {
			return null;
		}
		if (raw instanceof Boolean b) {
			return b;
		}
		return Boolean.parseBoolean(raw.toString());
	}

	private Locator<Key> appleKeyLocator() {
		return new Locator<>() {
			@Override
			public Key locate(Header header) {
				if (!(header instanceof JwsHeader jwsHeader)) {
					throw new CustomException(AuthErrorCode.A03_001);
				}
				String kid = jwsHeader.getKeyId();
				if (kid == null || kid.isBlank()) {
					throw new CustomException(AuthErrorCode.A03_001);
				}
				return resolvePublicKey(kid);
			}
		};
	}

	private PublicKey resolvePublicKey(String kid) {
		PublicKey cached = publicKeyCache.get(kid);
		if (cached != null) {
			return cached;
		}
		// kid 미스 → JWKS 강제 새로고침 후 한 번 더 조회.
		synchronized (refreshLock) {
			PublicKey afterLock = publicKeyCache.get(kid);
			if (afterLock != null) {
				return afterLock;
			}
			refreshJwks();
		}
		PublicKey refreshed = publicKeyCache.get(kid);
		if (refreshed == null) {
			log.warn("Apple JWKS 새로고침 후에도 kid 매칭 실패: kid={}", kid);
			throw new CustomException(AuthErrorCode.A03_001);
		}
		return refreshed;
	}

	private void refreshJwks() {
		try {
			ResponseEntity<String> response = restTemplate.getForEntity(APPLE_JWKS_URL, String.class);
			if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
				log.error("Apple JWKS 응답 비정상: status={}", response.getStatusCode());
				throw new CustomException(AuthErrorCode.A03_004);
			}

			JsonNode root = objectMapper.readTree(response.getBody());
			JsonNode keys = root.path("keys");
			if (!keys.isArray()) {
				log.error("Apple JWKS 형식 오류: keys 필드 없음");
				throw new CustomException(AuthErrorCode.A03_004);
			}

			Map<String, PublicKey> next = new ConcurrentHashMap<>();
			for (JsonNode keyNode : keys) {
				try {
					String json = objectMapper.writeValueAsString(keyNode);
					Jwk<?> jwk = Jwks.parser().build().parse(json);
					Key key = jwk.toKey();
					if (key instanceof PublicKey publicKey && jwk.getId() != null) {
						next.put(jwk.getId(), publicKey);
					}
				} catch (Exception e) {
					log.warn("Apple JWK 항목 파싱 실패, skip: {}", e.getMessage());
				}
			}
			if (next.isEmpty()) {
				log.error("Apple JWKS 파싱 결과가 비어 있음");
				throw new CustomException(AuthErrorCode.A03_004);
			}

			// 키 롤오버를 반영하기 위해 캐시 전체 교체.
			publicKeyCache.clear();
			publicKeyCache.putAll(next);
		} catch (RestClientException e) {
			log.error("Apple JWKS 조회 실패", e);
			throw new CustomException(AuthErrorCode.A03_004);
		} catch (CustomException e) {
			throw e;
		} catch (Exception e) {
			log.error("Apple JWKS 처리 중 알 수 없는 오류", e);
			throw new CustomException(AuthErrorCode.A03_004);
		}
	}
}
