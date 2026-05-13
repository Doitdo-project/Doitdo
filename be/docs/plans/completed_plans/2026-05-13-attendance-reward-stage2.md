# 일일 출석 보상 신규 구현 — Stage 2

- **작성일:** 2026-05-13
- **MR 단위:** Stage 2 단독 MR (`[BE : feat] 일일 출석 보상 도입`)
- **선행:** Stage 1 (`completed_plans/2026-05-13-earning-policy-revision-stage1.md`)
- **후속:** Stage 3 (캐릭터 EXP DB 변경 75/100/125)

---

## 1. 정책

| 항목 | 값 |
|------|------|
| 보상 금액 | **100 뚜레딧** |
| 일일 한도 | **1회 / 1일** |
| 한도 판별 기준 | **`Asia/Seoul` 자정** (Stage 1 통일 기준) |
| 일일 cap 검사 | **bypassDailyCap=true** (1일 1회는 자체 차단으로 보장. SOURCE_DAILY_CAP/COMBINED_DAILY_CAP 무관) |
| 동시성 제어 | **불필요** (FE 가 디바운스로 마지막 요청만 전송) |
| 트리거 | **명시적 API 호출** (앱 진입 시 자동 적립이 아니라 FE 가 의도적으로 호출) |

> **Streak 와 다름**: Streak 는 "오늘 TODO 1개 이상 완료 → 연속일 카운트 → 7일 단위 보상" 이라는 행위 의존 보상. Attendance 는 "앱 진입 1회당 100 뚜레딧" 이라는 단순 일일 보상. 두 도메인은 분리.

---

## 2. 신규 도메인 패키지

새 도메인 `attendance` 신설. 기존 도메인(`user`, `streak`, `tamagotchi`) 과 동급.

```
com.doitdo.domain.attendance
├── api
│   ├── controller
│   │   └── AttendanceController.java
│   └── dto
│       └── resp
│           └── AttendanceClaimResp.java
├── application
│   ├── AttendanceService.java          (interface)
│   └── impl
│       └── AttendanceServiceImpl.java
└── (entity / repository 없음 — wallet_earn_logs 재사용)
```

---

## 3. 변경 명세

### 3.1 `WalletEarnSource` enum 신규 값

**파일:** `src/main/java/com/doitdo/domain/user/entity/WalletEarnSource.java`

```java
public enum WalletEarnSource {
    SIGNUP_BONUS,
    STREAK_7DAY,
    PET_TOUCH,
    TODO_COMPLETION,
    DAILY_ATTENDANCE  // 신규 — 100 뚜레딧, 일일 1회, bypassDailyCap=true
}
```

> `DAILY_CAPPED_SOURCES` 리스트에는 **추가하지 않는다** (cap 무관).

---

### 3.2 적립 API 신설

#### Controller

**신규 파일:** `src/main/java/com/doitdo/domain/attendance/api/controller/AttendanceController.java`

```
POST /api/users/me/attendance
- 인증 필수 (@AuthenticationPrincipal CustomUserDetails)
- 요청 body 없음
- 응답: GlobalApiResponse<AttendanceClaimResp>
- 성공 시: 200 + 적립 정보
- 이미 오늘 수령 시: 적절한 ErrorCode (예: 신규 U07-001 "이미 오늘 출석 보상을 수령했다")
```

#### Service interface

**신규 파일:** `src/main/java/com/doitdo/domain/attendance/application/AttendanceService.java`

```java
public interface AttendanceService {
    AttendanceClaimResp claim(Long userId);
}
```

#### Service impl

**신규 파일:** `src/main/java/com/doitdo/domain/attendance/application/impl/AttendanceServiceImpl.java`

핵심 로직:
1. `Asia/Seoul` 기준 오늘 0시 ~ 내일 0시 범위 계산
2. `walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(userId, DAILY_ATTENDANCE, startOfDay, endOfDay) > 0` → 이미 수령 → ErrorCode 던지기
3. 미수령 → `creditEarnService.tryEarn(userId, DAILY_ATTENDANCE, 100, refId=null, bypassDailyCap=true)` 호출
4. 적립 후 wallet 잔액 조회해서 `AttendanceClaimResp` 반환

#### Response DTO

**신규 파일:** `src/main/java/com/doitdo/domain/attendance/api/dto/resp/AttendanceClaimResp.java`

```java
public record AttendanceClaimResp(
    int earnedAmount,        // 100
    long balance,            // 적립 후 wallet 잔액
    LocalDate attendanceDate // Asia/Seoul 기준 오늘
) {}
```

---

### 3.3 `UserInfoResp` 에 `dailyAttendanceClaimed` 추가

**파일:** `src/main/java/com/doitdo/domain/user/api/dto/resp/UserInfoResp.java`

```java
public record UserInfoResp(
    Long userId,
    String username,
    String email,
    boolean hasPassword,
    boolean birthDateRegistered,
    boolean agreementsAccepted,
    boolean dailyAttendanceClaimed   // 신규 — 오늘 출석 보상 수령 여부 (Asia/Seoul)
) {
    // 기존 from(User) 정적 팩토리는 유지 또는 제거하고, 새 시그니처 추가
    public static UserInfoResp from(User user, boolean dailyAttendanceClaimed) { ... }
}
```

> 기존 `from(User)` 호출부 모두 갱신 필요 (`UserServiceImpl.getMyInfo`, 소셜 로그인 응답 생성부 등). **로그인 응답에서도 boolean 을 채우려면 같은 SUM 조회가 들어가야 함** — Codex 가 호출부 전수 검토 후 처리할 것.

---

### 3.4 `UserServiceImpl.getMyInfo` 변경

**파일:** `src/main/java/com/doitdo/domain/user/application/impl/UserServiceImpl.java`

기존:
```java
public UserInfoResp getMyInfo(Long userId) {
    User user = userRepository.findById(userId).orElseThrow(...);
    return UserInfoResp.from(user);
}
```

신규:
```java
public UserInfoResp getMyInfo(Long userId) {
    User user = userRepository.findById(userId).orElseThrow(...);
    boolean claimed = isAttendanceClaimedToday(userId);  // SUM > 0
    return UserInfoResp.from(user, claimed);
}
```

→ 이를 위해 `WalletEarnLogRepository` 또는 별도 query helper 의존 추가. 같은 user 도메인 안이라 직접 의존 OK.

---

## 4. 신규 ErrorCode

**파일:** `src/main/java/com/doitdo/global/exception/code/ErrorCode.java` (또는 해당 enum 파일 위치)

| 코드 | 의미 | HTTP |
|------|------|------|
| `U07-001` | 이미 오늘 출석 보상을 수령했다 | 409 |

> 코드 prefix 는 user 도메인 (`U`) + 새 카테고리 (`07`). 기존 코드 충돌 없는지 Codex 가 확인 후 결정.

`docs/api/error-codes.md` 동시 갱신.

---

## 5. 통합 테스트

**신규 파일:** `src/test/java/com/doitdo/integration/AttendanceRewardIntegrationTest.java`

| Case | 시나리오 | 기대 결과 |
|------|---------|---------|
| 1 | 신규 사용자, POST /attendance 첫 호출 | 200, earnedAmount=100, balance=+100, wallet_earn_logs 1건 |
| 2 | 같은 날 두 번째 호출 | 409 (U07-001), 적립 안 됨, 잔액 변동 없음 |
| 3 | 자정 (Asia/Seoul) 경과 후 재호출 | 200, +100 추가 적립 |
| 4 | GET /api/users/me 응답에 `dailyAttendanceClaimed=true` (적립 후) | true 반환 |
| 5 | GET /api/users/me 응답에 `dailyAttendanceClaimed=false` (적립 전) | false 반환 |
| 6 | DAILY_ATTENDANCE 가 SOURCE_DAILY_CAP 에 영향 없는지 | 같은 날 PET_TOUCH 100, TODO 100 모두 받아도 attendance 100 적립 가능 |

---

## 6. docs 갱신 (동시)

| 문서 | 갱신 내용 |
|------|---------|
| `docs/api/error-codes.md` | `U07-001` 신규 추가 |
| `docs/api/response-format.md` | `UserInfoResp` 필드 추가 (있으면) |
| `docs/api/swagger.md` | `POST /api/users/me/attendance` 엔드포인트 추가 |
| `docs/architecture/erd.md` | `wallet_earn_logs.source` 에 `DAILY_ATTENDANCE` enum 값 추가 명시 |
| `docs/plans/completed_plans/2026-05-07-doredit-earning-system-design.md` | "Stage 2 attendance 추가 반영" 주석 |

---

## 7. 영향 파일 전체 목록

### 신규 생성 (6개)
- `src/main/java/com/doitdo/domain/attendance/api/controller/AttendanceController.java`
- `src/main/java/com/doitdo/domain/attendance/api/dto/resp/AttendanceClaimResp.java`
- `src/main/java/com/doitdo/domain/attendance/application/AttendanceService.java`
- `src/main/java/com/doitdo/domain/attendance/application/impl/AttendanceServiceImpl.java`
- `src/test/java/com/doitdo/integration/AttendanceRewardIntegrationTest.java`
- (선택) `src/test/java/com/doitdo/domain/attendance/application/impl/AttendanceServiceImplTest.java`

### 변경
- `src/main/java/com/doitdo/domain/user/entity/WalletEarnSource.java` — enum 값 추가
- `src/main/java/com/doitdo/domain/user/api/dto/resp/UserInfoResp.java` — boolean 필드 추가
- `src/main/java/com/doitdo/domain/user/application/impl/UserServiceImpl.java` — getMyInfo SUM 조회
- (전수) `UserInfoResp.from(...)` 호출부 모두 — 새 시그니처 적용
- `ErrorCode` enum 또는 해당 파일 — `U07-001` 추가

### docs
- `docs/api/error-codes.md`, `response-format.md`, `swagger.md`, `architecture/erd.md`
- 원설계 문서 주석

### 마이그레이션
- **없음** (`wallet_earn_logs.source` 컬럼은 ENUM/VARCHAR 어느 쪽이든 새 값 추가에 DDL 변경 불필요. JPA `@Enumerated(EnumType.STRING)` 가정.)

---

## 8. 완료 기준 (DoD)

1. 신규 도메인 `attendance` 패키지 생성 + 4개 클래스 구현
2. `WalletEarnSource.DAILY_ATTENDANCE` 추가 + cap 무관 처리 확인
3. `UserInfoResp` 신규 필드 + 모든 호출부 갱신
4. `UserServiceImpl.getMyInfo` SUM 조회로 boolean 채움
5. 신규 `U07-001` ErrorCode 추가 + docs 갱신
6. 통합 테스트 6개 Case 추가, **전부 통과**
7. `./gradlew test` 전체 통과 (Stage 1 의 214건 + 신규 케이스)
8. `./gradlew build` 통과
9. docs 동시 갱신 (4개 파일)
10. 커밋 메시지: `feat: 일일 출석 보상 도입 (100뚜레딧/일 1회)`

---

## 9. 작업하지 않는 것 (Out of Scope)

- 출석 통계/캘린더 화면용 조회 API (월별 출석 일자 등)
- 연속 출석 streak (Streak 도메인은 별개 — TODO 기반)
- 푸시 알림 ("오늘 출석 보상이 남았어요")
- 출석 이력 저장용 별도 테이블 (`user_daily_attendances` 같은) — `wallet_earn_logs` 만으로 충분
- Stage 3 (캐릭터 EXP DB 변경)

---

## 10. 제약 (Codex 위임 시 필수)

CDP MCP(Chrome DevTools Protocol MCP)는 절대 사용하지 않는다. 브라우저 자동화, DOM 접근, 스크린샷 등 CDP 관련 도구 일체 금지.
