# 출석 보상 자동 적립 (Lazy Claim) — Stage 5

- **작성일:** 2026-05-13
- **MR 단위:** Stage 5 단독 MR (`[BE : refactor] 출석 보상 자동 적립으로 전환`)
- **브랜치:** `be/refactor/attendance-auto-claim` (origin/dev `88b5706` 에서 분기)
- **선행:** Stage 2 (`MR #273` 머지)
- **병렬:** Stage 3 (캐릭터 EXP) — 영향 영역 다름, 충돌 없음

---

## 1. 동작 정의

| 호출 시점 | 응답 `dailyAttendanceClaimed` | 백엔드 처리 |
|---|---|---|
| **그날 첫 GET /api/users/me** | **`false`** | 자동 100뚜레딧 적립 + WalletEarnLog 기록 |
| **그날 두 번째 이후 GET /api/users/me** | **`true`** | 변동 없음 |

**의미 재정의**:
- `false` = "이번 호출 이전엔 안 받았었다" = **"방금 자동 적립됨"** → FE 가 토스트/모달 등으로 "+100뚜레딧" 안내
- `true` = "이번 호출 이전에 이미 받았다" = 평소 표시

**기준 시각**: `Asia/Seoul` 자정 (Stage 2 와 동일)

---

## 2. 변경 명세

### 2.1 `UserServiceImpl.getMyInfo()` 자동 적립 로직

**파일:** `src/main/java/com/doitdo/domain/user/application/impl/UserServiceImpl.java`

```java
@Override
@Transactional   // 트랜잭션 활성화 (자동 적립 + WalletEarnLog 기록)
public UserInfoResp getMyInfo(Long userId) {
    User user = userRepository.findById(userId)
            .orElseThrow(() -> new CustomException(UserErrorCode.U00_001));

    boolean alreadyClaimed = isAttendanceClaimedToday(userId);
    if (!alreadyClaimed) {
        // 첫 호출 → 자동 적립 (bypassDailyCap=true 로 cap 무관)
        creditEarnService.tryEarn(
                userId,
                WalletEarnSource.DAILY_ATTENDANCE,
                DAILY_ATTENDANCE_REWARD,  // 100
                null,
                true
        );
    }
    return UserInfoResp.from(user, alreadyClaimed);
    // ↑ alreadyClaimed=false 면 방금 적립한 의미. 응답 그대로 false.
    //   FE 가 false 받으면 토스트 "+100" 표시.
}

private boolean isAttendanceClaimedToday(Long userId) {
    LocalDate today = LocalDate.now(ZoneId.of("Asia/Seoul"));
    LocalDateTime start = today.atStartOfDay();
    LocalDateTime end = today.plusDays(1).atStartOfDay();
    return walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
            userId, WalletEarnSource.DAILY_ATTENDANCE, start, end
    ) > 0;
}
```

**상수 추가**:
```java
private static final int DAILY_ATTENDANCE_REWARD = 100;
```

**의존성 추가**:
- `CreditEarnService` (기존 의존성에 없으면 추가)
- `WalletEarnLogRepository` (기존 의존성에 없으면 추가)

### 2.2 `UserInfoResp` — 의미 재정의만 (구조 변경 없음)

**파일:** `src/main/java/com/doitdo/domain/user/api/dto/resp/UserInfoResp.java`

필드는 그대로. **JavaDoc 만 갱신**:

```java
/**
 * ...
 *
 * <p>{@code dailyAttendanceClaimed} 는 "이번 GET 호출 이전에 오늘 출석 보상을 이미
 * 받았는지" 를 나타낸다.
 * <ul>
 *   <li>{@code false} → 이번 호출에서 백엔드가 자동으로 100 뚜레딧을 적립했다.
 *       FE 는 토스트/모달 등으로 "+100 뚜레딧 획득" 안내를 표시할 수 있다.</li>
 *   <li>{@code true} → 오늘 이미 받았다. 변동 없음.</li>
 * </ul>
 * 기준 시각은 {@code Asia/Seoul} 자정.
 */
```

### 2.3 attendance 도메인 패키지 전체 삭제

**삭제 대상:**
- `src/main/java/com/doitdo/domain/attendance/` (전체)
  - `api/controller/AttendanceController.java`
  - `api/dto/resp/AttendanceClaimResp.java`
  - `application/AttendanceService.java`
  - `application/impl/AttendanceServiceImpl.java`
- `src/test/java/com/doitdo/integration/AttendanceRewardIntegrationTest.java` (POST 시나리오) — Stage 5 에서 GET /me 시나리오 테스트로 대체

> `attendance` 도메인 자체 제거. 자동 적립은 `user` 도메인 내부에서 처리.

### 2.4 `UserErrorCode.U07_001` — 제거 또는 유지 결정

- POST 엔드포인트 사라지므로 `U07-001` 도 더 이상 throw 안 됨
- **권장: 제거** (`UserErrorCode.java` 에서 enum 값 + `error-codes.md` 항목 삭제)
- 만약 다른 곳에서 참조하면 유지 (Codex 가 grep 후 결정)

### 2.5 자동 적립 시 동시성

- FE 가 일반적으로 GET /me 를 앱 진입 시 1회만 호출 → race 거의 없음
- 만약 동시 요청 우려되면 `@Transactional(isolation=Isolation.READ_COMMITTED)` 기본 + Wallet PESSIMISTIC_WRITE 락 추가 검토
- **기본 정책**: 단순 `@Transactional` 만 적용. PESSIMISTIC 락 추가는 보수적 접근으로 보류 (Stage 2 와 동일 정책)

---

## 3. 신규/변경 테스트

**파일 변경:** `AttendanceRewardIntegrationTest.java` 통째 재작성 또는 Stage 5 시나리오에 맞게 갱신

| Case | 시나리오 | 기대 결과 |
|------|---------|---------|
| 1 | 신규 사용자, 첫 GET /api/users/me | 응답 `dailyAttendanceClaimed=false`, wallet balance +100, WalletEarnLog 1건 추가 |
| 2 | 같은 날 두 번째 GET /api/users/me | 응답 `dailyAttendanceClaimed=true`, wallet 변동 없음 |
| 3 | 같은 날 세 번째 GET (race 시뮬) | 응답 `dailyAttendanceClaimed=true`, wallet 변동 없음 (적립 1회만) |
| 4 | Asia/Seoul 자정 경과 후 첫 GET | 응답 `dailyAttendanceClaimed=false`, wallet +100 추가 |
| 5 | DAILY_ATTENDANCE 가 SOURCE/COMBINED cap 에 영향 없는지 | PET_TOUCH 100 + TODO 100 받은 날에도 attendance 100 자동 적립 |

---

## 4. docs 갱신

| 문서 | 갱신 |
|---|---|
| `docs/api/swagger.md` | `POST /api/users/me/attendance` 제거. `GET /api/users/me` 의 `dailyAttendanceClaimed` 의미 갱신 (false=방금 적립). |
| `docs/api/response-format.md` | `UserInfoResp` 필드 설명에 자동 적립 의미 명시 |
| `docs/api/error-codes.md` | `U07-001` 제거 (또는 deprecated 표시) |
| `docs/architecture/erd.md` | `DAILY_ATTENDANCE` source 설명에 "GET /api/users/me 호출 시 자동 적립" 명시 |
| `docs/architecture/package-layout.md` | `attendance` 도메인 항목 제거 |
| `docs/plans/completed_plans/2026-05-13-attendance-reward-stage2.md` | "Stage 5 에서 자동 적립으로 전환" 주석 |

---

## 5. 영향 파일 전체 목록

### 삭제
- `src/main/java/com/doitdo/domain/attendance/` 전체 (4개 클래스)
- `src/main/java/com/doitdo/global/exception/UserErrorCode.java` 의 `U07_001` enum 값 (선택)

### 변경
- `src/main/java/com/doitdo/domain/user/application/impl/UserServiceImpl.java` — getMyInfo 자동 적립 추가, @Transactional, 의존성 추가
- `src/main/java/com/doitdo/domain/user/api/dto/resp/UserInfoResp.java` — JavaDoc 갱신
- `src/test/java/com/doitdo/integration/AttendanceRewardIntegrationTest.java` — POST 시나리오 → GET /me 시나리오
- docs 5~6 개

### 변경 없음
- `WalletEarnSource.DAILY_ATTENDANCE` enum — 유지
- `CreditEarnService.tryEarn` — 유지 (호출 위치만 변경)
- `WalletEarnLogRepository.sumAmountByUserIdAndSourceAndDate` — 그대로 재사용

---

## 6. 완료 기준 (DoD)

1. attendance 도메인 패키지 완전 삭제
2. `UserServiceImpl.getMyInfo()` 자동 적립 로직 추가 + `@Transactional`
3. `UserInfoResp` JavaDoc 갱신
4. `AttendanceRewardIntegrationTest` 통째 재작성 (GET /me 기반 5 시나리오)
5. `./gradlew test` 전체 통과
6. `./gradlew build` 통과
7. docs 동시 갱신
8. 커밋 메시지: `refactor: 출석 보상을 GET /me 자동 적립(lazy claim)으로 전환`

---

## 7. 작업하지 않는 것 (Out of Scope)

- `WalletEarnSource.DAILY_ATTENDANCE` enum 자체 변경
- Stage 3 (캐릭터 EXP), Stage 4 (똥치우기)
- FE 측 토스트/모달 구현 (BE 영역 아님)

---

## 8. 제약 (Codex 위임 시 필수)

CDP MCP(Chrome DevTools Protocol MCP)는 절대 사용하지 않는다. 브라우저 자동화, DOM 접근, 스크린샷 등 CDP 관련 도구 일체 금지.
