package com.doitdo.global.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import java.io.FileInputStream;
import java.io.IOException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;

@Configuration
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "true")
public class FirebaseConfig {

	@Bean
	public FirebaseApp firebaseApp(
			@Value("${firebase.service-account-path}") String serviceAccountPath,
			@Value("${firebase.project-id:}") String projectId) throws IOException {
		if (!StringUtils.hasText(serviceAccountPath)) {
			throw new IllegalStateException("firebase.service-account-path 가 비어 있습니다.");
		}

		try (FileInputStream inputStream = new FileInputStream(serviceAccountPath)) {
			FirebaseOptions.Builder builder = FirebaseOptions.builder()
					.setCredentials(GoogleCredentials.fromStream(inputStream));
			if (StringUtils.hasText(projectId)) {
				builder.setProjectId(projectId);
			}
			return FirebaseApp.initializeApp(builder.build());
		}
	}

	@Bean
	public FirebaseMessaging firebaseMessaging(FirebaseApp firebaseApp) {
		return FirebaseMessaging.getInstance(firebaseApp);
	}
}
