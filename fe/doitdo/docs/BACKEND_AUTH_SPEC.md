# 소셜 로그인 — FE 적용 스펙

백엔드로부터 전달받은 OAuth 명세를 프론트 코드에 반영한 결과를 기록.
명세 변경 시 이 문서 + 관련 코드 함께 수정.

## 서버 URL

| 환경 | Base URL |
|---|---|
| 개발 | `https://dev-api.doitdo.site` |
| 운영 | `https://api.doitdo.site` |

HTTPS + Cloudflare SSL Full (strict) 적용됨.

`.env` 의 `API_BASE_URL` 에 위 중 하나 입력.

## 엔드포인트

### 소셜 로그인 (통합)

```
POST {base}/auth/social/{provider}
```

| 항목 | 값 |
|---|---|
| provider | `GOOGLE` 또는 `KAKAO` (대문자) |
| body | `{ "accessToken": "..." }` |
| accessToken 출처 | 각 모바일 SDK 가 반환한 access token |

**예:**
```
POST https://dev-api.doitdo.site/auth/social/GOOGLE
Content-Type: application/json

{
  "accessToken": "ya29.a0AfH6SMB..."
}
```

### 서버 동작

1. 프론트가 보낸 accessToken 으로 해당 제공자의 userinfo API 호출
   - Google: `https://www.googleapis.com/oauth2/v3/userinfo`
   - Kakao: `https://kapi.kakao.com/v2/user/me`
2. 응답으로 받은 제공자 user id + email 로 DB 조회
   - 신규: 회원가입 처리
   - 기존: 로그인 처리
3. 우리 서비스 JWT 발급해서 응답

### 응답 (프론트 가정, 서버 실제 포맷 확인 필요)

```json
{
  "accessToken": "우리 서비스 JWT",
  "refreshToken": "리프레시 토큰",
  "user": {
    "id": 1,
    "nickname": "...",
    "email": "..."
  }
}
```

> 실제 응답 포맷(필드명)은 백엔드 확정 후 `AuthResponseDto.fromJson` 매핑 조정 필요.

## 프론트에서 토큰 사용

- 저장: `flutter_secure_storage` (iOS Keychain / Android EncryptedSharedPreferences)
- 부착: Dio interceptor 가 `Authorization: Bearer {accessToken}` 헤더 자동 부착
- 제외 경로: `/auth/*` (로그인 자체는 인증 헤더 불필요)

## 프론트 코드 매핑

| 스펙 | 구현 위치 |
|---|---|
| `POST /auth/social/GOOGLE` | `AuthRemoteDataSource.loginWithGoogle` |
| `POST /auth/social/KAKAO` | `AuthRemoteDataSource.loginWithKakao` |
| `POST /auth/logout` | `AuthRemoteDataSource.logout` |
| Google SDK accessToken 추출 | `AuthRepositoryImpl.signInWithGoogle` |
| Kakao SDK accessToken 추출 (카톡/웹 폴백 포함) | `AuthRepositoryImpl.signInWithKakao` |
| 토큰 저장 | `AuthLocalDataSource.save` |

> Kakao 네이티브 설정(앱 키, 키 해시 등)은 `docs/KAKAO_SETUP.md` 참고.

## 확인 필요한 것 (백엔드 팀에 재문의)

- [ ] 응답 JSON 필드명 (`accessToken` vs `token` 등)
- [ ] refresh 엔드포인트 (`/auth/refresh` 등)
- [ ] 토큰 만료 시간 (access / refresh)
- [ ] 에러 응답 포맷
- [ ] 회원탈퇴 엔드포인트 (App Store 심사 필수)
- [ ] Apple 로그인 지원 여부 (`/auth/social/APPLE`?)
