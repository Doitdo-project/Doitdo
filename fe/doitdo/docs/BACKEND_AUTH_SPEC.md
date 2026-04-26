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
    "userId": 1,
    "username": "...",
    "email": "...",
    "hasPassword": true
  }
}
```

> 실제 응답 포맷(필드명)은 백엔드 확정 후 `AuthResponseDto.fromJson` 매핑 조정 필요.
>
> `hasPassword` — 일반 가입자(이메일/비번)는 true, 소셜 전용 가입자는 false.
> 프론트는 이 값으로 "비밀번호 변경" 진입을 분기한다(소셜 전용은 행 자체를 숨김).

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
- [ ] 응답 JSON 필드명 / refresh 엔드포인트 / 토큰 만료 시간 / 에러 응답 포맷 — 위 항목들 후속 확인.
- [x] **회원탈퇴 엔드포인트** — `DELETE /api/users/me` 구현 완료.
  - 일반 계정: 비밀번호 재인증 후 진행.
  - OAuth 계정: access token 인증만으로 진행.
  - Apple 사용자는 자동으로 Apple `/auth/revoke` 호출 (App Store 5.1.1(v) + Apple Developer 정책 준수).
- [x] **Apple 로그인 지원 여부** — `POST /api/auth/social/APPLE` 구현 완료.
  - body: `{ "accessToken": "<Apple identityToken JWT>", "appleAuthorizationCode": "<authorizationCode>" }`
  - **`appleAuthorizationCode` 는 APPLE provider 에서 필수** (누락 시 `A03-002` 반환). 회원탈퇴 시 revoke 보장을 위해 엄격 검증.
  - 백엔드 처리 흐름:
    1. identityToken JWT 를 Apple JWKS 로 서명 검증 + `iss/aud/exp` 검증
    2. `authorizationCode` 를 Apple `/auth/token` 에 교환 → `refresh_token` 획득
    3. `refresh_token` 을 `auto_providers.apple_refresh_token` 에 저장 (재로그인 시 자동 갱신)
    4. 회원탈퇴 시 저장된 `refresh_token` 으로 Apple `/auth/revoke` 호출
  - 첫 로그인에서만 identityToken 에 email 이 포함되므로(이후 null) 신규 가입 경로에서 email 누락 시 `A03-001`.
  - "내 이메일 가리기" 선택 시 `@privaterelay.appleid.com` 릴레이 주소가 그대로 저장된다.
  - 서버 환경변수 (모두 필수, 누락 시 부팅 실패):
    - `APPLE_OAUTH_CLIENT_ID` (identityToken audience, 보통 앱 Bundle Identifier)
    - `APPLE_SIGNIN_TEAM_ID` (Apple Developer Team ID)
    - `APPLE_SIGNIN_KEY_ID` (Apple Sign-in Key ID)
    - `APPLE_SIGNIN_KEY_PATH` (.p8 파일 경로 — 상대경로 OK, working dir 기준)
    - `APPLE_SIGNIN_CLIENT_ID` (client_secret JWT 의 sub, 보통 Bundle Identifier)
