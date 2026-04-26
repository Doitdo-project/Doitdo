package com.doitdo.global.client.dto;

/**
 * Apple identityToken(JWT) 검증 결과.
 *
 * <ul>
 *   <li>{@code sub} — Apple 계정의 영구 식별자(provider_uid 로 사용)</li>
 *   <li>{@code email} — 첫 로그인 이후에는 null 또는 relay 이메일일 수 있음</li>
 *   <li>{@code emailVerified} — Apple 이 이메일 소유 검증을 완료했는지 여부</li>
 * </ul>
 */
public record AppleUserInfo(

		String sub,
		String email,
		Boolean emailVerified
) {
}
