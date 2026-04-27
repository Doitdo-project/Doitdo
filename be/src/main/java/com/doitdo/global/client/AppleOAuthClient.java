package com.doitdo.global.client;

import com.doitdo.global.exception.AuthErrorCode;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.util.AppleClientSecretGenerator;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

/**
 * Apple OAuth REST 호출 클라이언트.
 *
 * <ul>
 *   <li>{@link #exchangeCodeForRefreshToken(String)} — 로그인 시 authorizationCode → refresh_token 교환</li>
 *   <li>{@link #revokeRefreshToken(String)} — 회원탈퇴 시 Apple 측 토큰 무효화 (App Store 정책 요구)</li>
 * </ul>
 *
 * <p>두 호출 모두:
 * <ul>
 *   <li>{@code Content-Type: application/x-www-form-urlencoded}</li>
 *   <li>{@code client_secret} = {@link AppleClientSecretGenerator#generate()} (ES256 JWT)</li>
 *   <li>실패 시 {@link CustomException} ({@link AuthErrorCode#A03_004}) 으로 변환</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AppleOAuthClient {

	private static final String APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token";
	private static final String APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke";

	private final RestTemplate restTemplate;
	private final AppleClientSecretGenerator clientSecretGenerator;
	private final ObjectMapper objectMapper = new ObjectMapper();

	@Value("${apple.signin.client-id:}")
	private String clientId;

	/**
	 * 클라이언트가 보낸 1회용 {@code authorizationCode} 를 Apple 에 제출해 {@code refresh_token} 을 받아온다.
	 *
	 * <p>Apple 응답 본문 예:
	 * <pre>
	 * {
	 *   "access_token": "...",
	 *   "token_type": "Bearer",
	 *   "expires_in": 3600,
	 *   "refresh_token": "...",
	 *   "id_token": "..."
	 * }
	 * </pre>
	 *
	 * @return Apple refresh_token (응답에 누락 시 빈 문자열 대신 예외)
	 */
	public String exchangeCodeForRefreshToken(String authorizationCode) {
		MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
		form.add("client_id", clientId);
		form.add("client_secret", clientSecretGenerator.generate());
		form.add("code", authorizationCode);
		form.add("grant_type", "authorization_code");

		String body = post(APPLE_TOKEN_URL, form, "code 교환");
		try {
			JsonNode root = objectMapper.readTree(body);
			JsonNode refresh = root.get("refresh_token");
			if (refresh == null || refresh.asText().isBlank()) {
				log.error("Apple /auth/token 응답에 refresh_token 누락: {}", body);
				throw new CustomException(AuthErrorCode.A03_004);
			}
			return refresh.asText();
		} catch (CustomException e) {
			throw e;
		} catch (Exception e) {
			log.error("Apple /auth/token 응답 파싱 실패", e);
			throw new CustomException(AuthErrorCode.A03_004);
		}
	}

	/**
	 * 회원탈퇴 시 Apple 측 토큰을 무효화. App Store 정책 5.1.1(v) + Apple Developer 가이드 충족.
	 *
	 * <p>호출자(예: {@code UserServiceImpl.withdraw}) 가 베스트 에포트로 처리 — 실패해도
	 * 우리 DB 의 회원탈퇴 자체는 정상 완료되어야 한다.
	 */
	public void revokeRefreshToken(String refreshToken) {
		MultiValueMap<String, String> form = new LinkedMultiValueMap<>();
		form.add("client_id", clientId);
		form.add("client_secret", clientSecretGenerator.generate());
		form.add("token", refreshToken);
		form.add("token_type_hint", "refresh_token");

		post(APPLE_REVOKE_URL, form, "revoke");
	}

	private String post(String url, MultiValueMap<String, String> form, String opName) {
		HttpHeaders headers = new HttpHeaders();
		headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
		HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(form, headers);

		try {
			ResponseEntity<String> response = restTemplate.exchange(
					url, HttpMethod.POST, request, String.class
			);
			if (!response.getStatusCode().is2xxSuccessful()) {
				log.warn("Apple {} 비정상 status: {}, body: {}", opName, response.getStatusCode(), response.getBody());
				throw new CustomException(AuthErrorCode.A03_004);
			}
			return response.getBody();
		} catch (HttpClientErrorException e) {
			// Apple 은 4xx 에 invalid_grant / invalid_client 등을 본문 JSON 으로 내려준다.
			log.warn("Apple {} HTTP error: status={}, body={}", opName, e.getStatusCode(), e.getResponseBodyAsString());
			throw new CustomException(AuthErrorCode.A03_004);
		} catch (RestClientException e) {
			log.error("Apple {} 호출 실패", opName, e);
			throw new CustomException(AuthErrorCode.A03_004);
		}
	}
}
