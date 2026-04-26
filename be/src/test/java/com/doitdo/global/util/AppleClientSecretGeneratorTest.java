package com.doitdo.global.util;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.JwsHeader;
import io.jsonwebtoken.Jwts;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.ECPublicKey;
import java.security.spec.ECGenParameterSpec;
import java.util.Base64;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

/**
 * {@link AppleClientSecretGenerator} 가 PKCS#8 PEM 키를 정상 로딩하고 ES256 JWT 를 발급하는지 검증.
 *
 * <p>실제 Apple .p8 는 ssh 키처럼 secret 이라 테스트 fixture 로 둘 수 없다.
 * 대신 EC P-256 KeyPair 를 즉석 생성 → PKCS#8 PEM 으로 직렬화 → 임시 파일에 저장 후
 * 동일 흐름으로 검증한다 (.p8 형식과 100% 호환).
 */
class AppleClientSecretGeneratorTest {

	@Test
	void p8_파일을_로딩하고_ES256_JWT_를_발급한다(@TempDir Path tempDir) throws Exception {
		// given — Apple .p8 와 동일한 PKCS#8 PEM 형식의 EC P-256 키 페어 생성
		KeyPair keyPair = generateEcKeyPair();
		Path keyFile = tempDir.resolve("apple-test-key.p8");
		writePkcs8Pem(keyFile, keyPair.getPrivate().getEncoded());

		AppleClientSecretGenerator generator = new AppleClientSecretGenerator(
				"TEAM1234ID",
				"KEY5678ID",
				keyFile.toString(),
				"com.d107.doitdo"
		);
		generator.init();

		// when
		String jwt = generator.generate();

		// then — 발급한 JWT 를 페어의 공개키로 검증 가능해야 함
		Jws<Claims> parsed = Jwts.parser()
				.verifyWith((ECPublicKey) keyPair.getPublic())
				.build()
				.parseSignedClaims(jwt);

		JwsHeader header = parsed.getHeader();
		assertThat(header.getAlgorithm()).isEqualTo("ES256");
		assertThat(header.getKeyId()).isEqualTo("KEY5678ID");

		Claims claims = parsed.getPayload();
		assertThat(claims.getIssuer()).isEqualTo("TEAM1234ID");
		assertThat(claims.getAudience()).contains("https://appleid.apple.com");
		assertThat(claims.getSubject()).isEqualTo("com.d107.doitdo");
		assertThat(claims.getIssuedAt()).isNotNull();
		assertThat(claims.getExpiration()).isAfter(claims.getIssuedAt());
	}

	@Test
	void 필수_설정_누락_시_부팅_실패한다() {
		AppleClientSecretGenerator generator = new AppleClientSecretGenerator(
				"", "KEY", "/tmp/x.p8", "client"
		);
		assertThatThrownBy(generator::init)
				.isInstanceOf(IllegalStateException.class)
				.hasMessageContaining("apple.signin.team-id");
	}

	@Test
	void 키파일_누락_시_부팅_실패한다(@TempDir Path tempDir) {
		Path missing = tempDir.resolve("does-not-exist.p8");
		AppleClientSecretGenerator generator = new AppleClientSecretGenerator(
				"TEAM", "KEY", missing.toString(), "client"
		);
		assertThatThrownBy(generator::init)
				.isInstanceOf(IllegalStateException.class)
				.hasMessageContaining("찾을 수 없습니다");
	}

	private static KeyPair generateEcKeyPair() throws Exception {
		KeyPairGenerator kpg = KeyPairGenerator.getInstance("EC");
		kpg.initialize(new ECGenParameterSpec("secp256r1"));
		return kpg.generateKeyPair();
	}

	private static void writePkcs8Pem(Path target, byte[] der) throws IOException {
		String base64 = Base64.getMimeEncoder(64, "\n".getBytes()).encodeToString(der);
		String pem = "-----BEGIN PRIVATE KEY-----\n" + base64 + "\n-----END PRIVATE KEY-----\n";
		Files.writeString(target, pem);
	}
}
