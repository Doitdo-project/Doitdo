package com.doitdo.global.client;

import com.doitdo.global.client.dto.KakaoUserResp;
import com.doitdo.global.exception.AuthErrorCode;
import com.doitdo.global.exception.CustomException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

@Slf4j
@Component
@RequiredArgsConstructor
public class KakaoOAuthClient {

	private static final String KAKAO_USER_INFO_URL = "https://kapi.kakao.com/v2/user/me";

	private final RestTemplate restTemplate;

	public KakaoUserResp getUserInfo(String accessToken) {
		HttpHeaders headers = new HttpHeaders();
		headers.setBearerAuth(accessToken);

		HttpEntity<Void> request = new HttpEntity<>(headers);

		try {
			ResponseEntity<KakaoUserResp> response = restTemplate.exchange(
					KAKAO_USER_INFO_URL,
					HttpMethod.GET,
					request,
					KakaoUserResp.class
			);

			HttpStatusCode status = response.getStatusCode();
			if (!status.is2xxSuccessful() || response.getBody() == null) {
				log.warn("Kakao user info API non-2xx: status={}", status);
				throw new CustomException(AuthErrorCode.A03_004);
			}
			return response.getBody();
		} catch (HttpClientErrorException.Unauthorized e) {
			log.warn("Kakao access token unauthorized: {}", e.getMessage());
			throw new CustomException(AuthErrorCode.A03_001);
		} catch (HttpClientErrorException e) {
			log.warn("Kakao user info HTTP error: status={}, body={}", e.getStatusCode(), e.getResponseBodyAsString());
			throw new CustomException(AuthErrorCode.A03_004);
		} catch (RestClientException e) {
			log.error("Kakao user info call failed", e);
			throw new CustomException(AuthErrorCode.A03_004);
		}
	}
}
