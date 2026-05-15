package com.doitdo.global.exception;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.stream.Stream;

public final class ErrorCodeRegistry {

	private static final List<Class<? extends ErrorCode>> SOURCES = List.of(
		CommonErrorCode.class,
		AuthErrorCode.class,
		UserErrorCode.class,
		TodoErrorCode.class,
		TamagotchiErrorCode.class,
		InventoryErrorCode.class,
		ShopErrorCode.class,
		NotificationErrorCode.class,
		SettingErrorCode.class,
		BugReportErrorCode.class,
		NoticeErrorCode.class
	);

	private static final Map<String, ErrorCode> CODE_INDEX;

	static {
		Map<String, ErrorCode> index = new HashMap<>();
		SOURCES.stream()
			.flatMap(c -> Stream.of(c.getEnumConstants()))
			.forEach(ec -> {
				ErrorCode prev = index.put(ec.getCode(), ec);
				if (prev != null) {
					throw new IllegalStateException(
						"Duplicate ErrorCode: " + ec.getCode()
							+ " (" + prev + " ↔ " + ec + ")"
					);
				}
			});
		CODE_INDEX = Collections.unmodifiableMap(index);
	}

	private ErrorCodeRegistry() {}

	public static List<Class<? extends ErrorCode>> sources() {
		return SOURCES;
	}

	public static Optional<ErrorCode> find(String code) {
		return Optional.ofNullable(CODE_INDEX.get(code));
	}

	public static ErrorCode findOrThrow(String code) {
		return find(code).orElseThrow(() ->
			new NoSuchElementException("Unknown error code: " + code));
	}

	public static Collection<ErrorCode> all() {
		return CODE_INDEX.values();
	}

	public static List<ErrorCode> byPrefix(String prefix) {
		return CODE_INDEX.entrySet().stream()
			.filter(e -> e.getKey().startsWith(prefix))
			.map(Map.Entry::getValue)
			.toList();
	}

	public static int size() {
		return CODE_INDEX.size();
	}
}
