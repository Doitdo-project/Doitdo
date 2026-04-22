package com.doitdo.global.client;

import com.doitdo.global.client.dto.GoogleUserInfo;
import com.doitdo.global.exception.AuthErrorCode;
import com.doitdo.global.exception.CustomException;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken.Payload;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class GoogleIdTokenVerifierService {

	private final String clientId;
	private GoogleIdTokenVerifier verifier;

	public GoogleIdTokenVerifierService(@Value("${google.oauth.client-id:}") String clientId) {
		this.clientId = clientId;
	}

	@PostConstruct
	void init() {
		this.verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), GsonFactory.getDefaultInstance())
				.setAudience(clientId == null || clientId.isBlank()
						? Collections.emptyList()
						: Collections.singletonList(clientId))
				.build();
	}

	public GoogleUserInfo verify(String idTokenString) {
		try {
			GoogleIdToken idToken = verifier.verify(idTokenString);
			if (idToken == null) {
				log.warn("Google ID token verification failed: invalid signature/audience/expiration");
				throw new CustomException(AuthErrorCode.A03_001);
			}

			Payload payload = idToken.getPayload();
			String sub = payload.getSubject();
			String email = payload.getEmail();
			Object nameObj = payload.get("name");
			String name = nameObj == null ? null : nameObj.toString();

			return new GoogleUserInfo(sub, email, name);
		} catch (IllegalArgumentException e) {
			log.warn("Google ID token format invalid: {}", e.getMessage());
			throw new CustomException(AuthErrorCode.A03_001);
		} catch (GeneralSecurityException | IOException e) {
			log.error("Google ID token verification error", e);
			throw new CustomException(AuthErrorCode.A03_004);
		}
	}
}
