package com.doitdo.global.exception;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.NoSuchElementException;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class ErrorCodeRegistryTest {

	private static final Pattern CODE_PATTERN = Pattern.compile("^[A-Z]\\d{2}-\\d{3}$");

	@Test
	@DisplayName("모든 ErrorCode 는 형식 {LETTER}{NN}-{NNN} 을 따른다")
	void allCodesFollowFormat() {
		for (ErrorCode ec : ErrorCodeRegistry.all()) {
			assertThat(ec.getCode())
				.as("invalid format: %s (%s)", ec.getCode(), ec)
				.matches(CODE_PATTERN);
		}
	}

	@Test
	@DisplayName("코드 중복은 정적 초기화 시 IllegalStateException 으로 발견된다")
	void codesAreUnique() {
		// 정적 초기화에서 중복 시 throw 하므로 여기까지 도달했다는 것 자체가 검증
		Set<String> codes = ErrorCodeRegistry.all().stream()
			.map(ErrorCode::getCode)
			.collect(java.util.stream.Collectors.toSet());
		assertThat(codes).hasSize(ErrorCodeRegistry.size());
	}

	@Test
	@DisplayName("등록된 모든 enum 의 상수 합계와 Registry 크기가 일치한다")
	void allEnumsRegistered() {
		int total = ErrorCodeRegistry.sources().stream()
			.mapToInt(c -> c.getEnumConstants().length)
			.sum();
		assertThat(ErrorCodeRegistry.size()).isEqualTo(total);
	}

	@Test
	@DisplayName("find 는 코드 문자열로 ErrorCode 를 찾는다")
	void findReturnsErrorCode() {
		assertThat(ErrorCodeRegistry.find("A00-001"))
			.isPresent()
			.contains(AuthErrorCode.A00_001);
		assertThat(ErrorCodeRegistry.find("UNKNOWN-999")).isEmpty();
	}

	@Test
	@DisplayName("findOrThrow 는 미등록 코드에 NoSuchElementException 을 던진다")
	void findOrThrowOnMissing() {
		assertThatThrownBy(() -> ErrorCodeRegistry.findOrThrow("XX-999"))
			.isInstanceOf(NoSuchElementException.class)
			.hasMessageContaining("XX-999");
	}

	@Test
	@DisplayName("byPrefix 는 prefix 로 시작하는 모든 ErrorCode 를 반환한다")
	void byPrefixGroups() {
		assertThat(ErrorCodeRegistry.byPrefix("A00"))
			.allSatisfy(ec -> assertThat(ec.getCode()).startsWith("A00"))
			.hasSize((int) Stream.of(AuthErrorCode.values())
				.filter(ec -> ec.getCode().startsWith("A00"))
				.count());
	}

	@Test
	@DisplayName("도메인별 enum 은 해당 도메인 prefix(첫 글자) 로만 시작한다")
	void domainPrefixIntegrity() {
		assertPrefix(CommonErrorCode.class, 'G');
		assertPrefix(AuthErrorCode.class, 'A');
		assertPrefix(UserErrorCode.class, 'U');
		assertPrefix(TodoErrorCode.class, 'T');
		assertPrefix(TamagotchiErrorCode.class, 'M');
		assertPrefix(InventoryErrorCode.class, 'I');
		assertPrefix(ShopErrorCode.class, 'S');
		assertPrefix(NotificationErrorCode.class, 'N');
		assertPrefix(SettingErrorCode.class, 'C');
		assertPrefix(BugReportErrorCode.class, 'B');
	}

	private void assertPrefix(Class<? extends ErrorCode> enumClass, char expectedPrefix) {
		for (ErrorCode ec : enumClass.getEnumConstants()) {
			assertThat(ec.getCode().charAt(0))
				.as("%s.%s code=%s should start with '%s'",
					enumClass.getSimpleName(), ec, ec.getCode(), expectedPrefix)
				.isEqualTo(expectedPrefix);
		}
	}
}
