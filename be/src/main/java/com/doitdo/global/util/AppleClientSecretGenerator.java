package com.doitdo.global.util;

import com.doitdo.global.exception.AuthErrorCode;
import com.doitdo.global.exception.CustomException;
import io.jsonwebtoken.Jwts;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Duration;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Apple {@code /auth/token} · {@code /auth/revoke} 호출에 동봉되는 {@code client_secret} JWT 생성기.
 *
 * <p>Apple 명세 (https://developer.apple.com/documentation/sign_in_with_apple/generate_and_validate_tokens):
 * <ul>
 *   <li>header: {@code alg=ES256}, {@code kid=<Apple Sign-in Key ID>}</li>
 *   <li>claims:
 *     <ul>
 *       <li>{@code iss} = Apple Developer Team ID</li>
 *       <li>{@code aud} = {@code https://appleid.apple.com}</li>
 *       <li>{@code sub} = client_id (iOS native 의 경우 앱 Bundle Identifier)</li>
 *       <li>{@code iat} = 현재 시각</li>
 *       <li>{@code exp} = iat + 5분 (Apple 은 최대 6개월까지 허용하지만 보안상 짧게)</li>
 *     </ul>
 *   </li>
 *   <li>서명 키: Apple Developer 콘솔에서 발급한 {@code .p8} (PKCS#8 PEM 형식의 EC P-256 개인키)</li>
 * </ul>
 *
 * <p>{@code .p8} 는 부팅 시 1회 로딩 후 {@link PrivateKey} 로 캐시한다(파일 I/O · PEM 파싱 비용 절약).
 * 키 또는 설정이 누락된 상태로 부팅되면 {@link IllegalStateException} 으로 즉시 실패해
 * "런타임에 Apple 호출만 안 되는" 은밀한 장애를 방지한다.
 *
 * <p>BouncyCastle 미사용. {@code .p8} 는 PKCS#8 PEM 표준이므로 Java 표준 {@link KeyFactory} 로 충분.
 */
@Slf4j
@Component
public class AppleClientSecretGenerator {

	private static final String APPLE_AUDIENCE = "https://appleid.apple.com";
	private static final Duration CLIENT_SECRET_TTL = Duration.ofMinutes(5);

	private final String teamId;
	private final String keyId;
	private final String keyPath;
	private final String clientId;

	private PrivateKey privateKey;

	public AppleClientSecretGenerator(
			@Value("${apple.signin.team-id:}") String teamId,
			@Value("${apple.signin.key-id:}") String keyId,
			@Value("${apple.signin.key-path:}") String keyPath,
			@Value("${apple.signin.client-id:}") String clientId
	) {
		this.teamId = teamId;
		this.keyId = keyId;
		this.keyPath = keyPath;
		this.clientId = clientId;
	}

	@PostConstruct
	void init() {
		// 환경변수 누락은 부팅 시점에 명확히 에러를 띄운다.
		// 이렇게 해야 운영 배포 후 첫 Apple 로그인 시점에서야 발견되는 silent failure 를 막을 수 있다.
		ensurePresent("apple.signin.team-id", teamId);
		ensurePresent("apple.signin.key-id", keyId);
		ensurePresent("apple.signin.key-path", keyPath);
		ensurePresent("apple.signin.client-id", clientId);

		try {
			Path resolved = Path.of(keyPath);
			if (!Files.exists(resolved)) {
				throw new IllegalStateException(
						"Apple Sign-in 키 파일을 찾을 수 없습니다: " + resolved.toAbsolutePath()
								+ " (working dir=" + Path.of("").toAbsolutePath() + ")");
			}
			String pem = Files.readString(resolved);
			this.privateKey = parsePkcs8Pem(pem);
			log.info("Apple Sign-in client_secret generator initialized (kid={}, path={})",
					keyId, resolved.toAbsolutePath());
		} catch (IOException | NoSuchAlgorithmException | InvalidKeySpecException e) {
			throw new IllegalStateException("Apple Sign-in 키 로딩 실패", e);
		}
	}

	/**
	 * Apple 호출 직전마다 새 JWT 발급. (TTL 5분이라 재사용 캐시 가치 낮음.)
	 *
	 * @throws CustomException A03_004 — 서명 도중 알 수 없는 오류 (실질적으로 거의 발생 안 함)
	 */
	public String generate() {
		try {
			Instant now = Instant.now();
			return Jwts.builder()
					.header()
						.add("kid", keyId)
						.add("alg", "ES256")
						.and()
					.claims(Map.of(
							"iss", teamId,
							"aud", APPLE_AUDIENCE,
							"sub", clientId
					))
					.issuedAt(Date.from(now))
					.expiration(Date.from(now.plus(CLIENT_SECRET_TTL)))
					.signWith(privateKey, Jwts.SIG.ES256)
					.compact();
		} catch (Exception e) {
			log.error("Apple client_secret JWT 생성 실패", e);
			throw new CustomException(AuthErrorCode.A03_004);
		}
	}

	private static void ensurePresent(String name, String value) {
		if (value == null || value.isBlank()) {
			throw new IllegalStateException("필수 설정 누락: " + name);
		}
	}

	/**
	 * Apple .p8 (PKCS#8 PEM) → {@link PrivateKey} (EC P-256).
	 *
	 * <p>PEM 은 다음 형식:
	 * <pre>
	 * -----BEGIN PRIVATE KEY-----
	 * &lt;Base64 encoded PKCS#8 DER&gt;
	 * -----END PRIVATE KEY-----
	 * </pre>
	 */
	private static PrivateKey parsePkcs8Pem(String pem)
			throws NoSuchAlgorithmException, InvalidKeySpecException {
		String stripped = pem
				.replace("-----BEGIN PRIVATE KEY-----", "")
				.replace("-----END PRIVATE KEY-----", "")
				.replaceAll("\\s+", "");
		byte[] der = Base64.getDecoder().decode(stripped);
		PKCS8EncodedKeySpec spec = new PKCS8EncodedKeySpec(der);
		return KeyFactory.getInstance("EC").generatePrivate(spec);
	}
}
