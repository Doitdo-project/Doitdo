# 시스템 개요 (overview)

## 한 줄 정리

doitdo 백엔드는 **Spring Boot 3.5.x / Java 21 / JPA / MariaDB / Redis** 기반의 단일 모놀리스 서버이며, 도메인 단위로 격리된 패키지 구조를 따른다.

## 스택

| 영역 | 사양 |
|---|---|
| 언어 | Java 21 |
| 프레임워크 | Spring Boot 3.5.13, Spring Security, Spring Data JPA, Spring Data Redis, Spring Cache |
| API 문서 | springdoc-openapi 2.7.0 (`dev` / `local` 한정) |
| 빌드 | Gradle (Wrapper 포함) |
| DB | MariaDB |
| Cache | Redis |
| 인증 | JWT (BearerAuth) |

## 진입점

- 메인 클래스: `com.doitdo.DoitdoApplication`
- 베이스 패키지: `com.doitdo`

## 패키지 계층 (개념)

```
com.doitdo
 ├ DoitdoApplication        # @SpringBootApplication
 ├ domain/{도메인}           # 비즈니스 (auth, user, todo, tamagotchi, …)
 │   ├ api/                  # Controller + DTO
 │   ├ application/          # Service 인터페이스 + Impl
 │   ├ entity/               # JPA Entity
 │   └ repository/           # Spring Data JPA Repository
 └ global/                   # 공통 인프라
     ├ config/               # Security / OpenAPI / JpaAuditing / Redis
     ├ cache/                # Cache evict helpers
     ├ entity/               # BaseTimeEntity
     ├ exception/            # ErrorCode + GlobalExceptionHandler
     ├ swagger/              # @ApiErrorCodes + Customizer (be/feat/swagger 머지 후)
     ├ api/response/         # GlobalApiResponse<T>
     ├ util/                 # JwtUtil 등
     └ health/               # HealthController
```

상세 디렉토리 규약은 [`package-layout.md`](package-layout.md).

## 계층 책임

| 계층 | 책임 | 의존 방향 |
|---|---|---|
| `api/controller` | HTTP 입출력 매핑, 검증, 응답 포맷 | → application |
| `api/dto/{req,resp}` | 요청/응답 DTO | (계층 간 데이터 운반체) |
| `application/{Domain}Service` | 트랜잭션 경계, 유스케이스 | → repository, 다른 도메인은 Service 통해서만 |
| `application/impl/{Domain}ServiceImpl` | Service 구현 | → repository |
| `entity/{Domain}` | JPA Entity, 도메인 모델 | (자기 도메인 안에서만) |
| `repository/{Domain}Repository` | Spring Data JPA | → entity |
| `global/*` | 공통 인프라/유틸 | (어디서나 의존 가능) |

## 도메인 격리 원칙

- 도메인 간 직접 엔티티 참조 금지. FK는 **Long ID 필드**로만 보관 (`@ManyToOne` 미사용 원칙).
- 도메인 간 협력은 Service → Service 호출로.

## 응답/에러 표준

- 모든 응답: `GlobalApiResponse<T>` ([`../api/response-format.md`](../api/response-format.md))
- 에러 코드: 10개 도메인 enum + `ErrorCodeRegistry` 인덱스 ([`../api/error-codes.md`](../api/error-codes.md))
- 컨트롤러 작성: [`../api/swagger.md`](../api/swagger.md)

## 알림 플로우

모든 알림은 `NotificationService` 를 통해 `Notification` 테이블 저장 후 (DND 구간이 아니면) FCM 발송한다.
이벤트 기반 트리거는 `@TransactionalEventListener(AFTER_COMMIT)` + `@Transactional(REQUIRES_NEW)` 패턴으로 격리한다.

| 트리거 | NotificationType | 발화 위치 | referenceId | 비고 |
|---|---|---|---|---|
| 저녁 미완료 리마인더 | `REMINDER_EVENING` | `EveningReminderScheduler` → `NotificationService.sendEveningReminder` | null | 매분 cron, `UserSetting.eveningReminderTime` 일치 유저 대상, 미완료 TODO > 0 조건. 플래그: `notification.evening-reminder.enabled` |
| 아침 TODO 리마인더 | `REMINDER_MORNING` | `MorningReminderScheduler` → `NotificationService.sendMorningReminder` | null | 매분 cron, `UserSetting.morningReminderTime` 일치 유저 대상, 미완료 TODO > 0 조건. 플래그: `notification.morning-reminder.enabled` |
| 아침 스트릭 유지 유도 | `REMINDER_STREAK_TODO_EMPTY` | `MorningReminderScheduler` → `NotificationService.sendStreakTodoEmptyReminder` | null | 아침 리마인더 시각에 오늘 대상 TODO 가 0개이고, 어제까지 이어진 스트릭이 있으면 1일 1회 발송. |
| TODO 완료 | `TODO_DONE` | `TodoServiceImpl.changeStatus()` → `TodoCompletedEvent` → `TodoCompletedNotificationListener` | todoId | DONE 전이 시 1회 발행. 기존 `TodoCompletionExpListener` 와 분리 |
| TODO 알림 시각 | `TODO_REMINDER` | `TodoAlertScheduler` → `NotificationService.sendTodoAlert` | todoId | 매분 cron, `Todo.alertTime` 일치 + 당일 대상. 기존 FCM 직접 호출을 NotificationService 경유로 교체 (DB 저장 추가) |
| TODO 미루기 | `TODO_SNOOZED` | `TodoSnoozedNotificationListener` | todoId | 비활성화. Bean 과 이벤트 리스너 메서드는 유지하되 본문은 no-op |
| 다마고치 독립 준비 완료 | `TAMAGOTCHI_FAREWELL` | `TodoCompletionExpListener` 에서 ADULT cap 도달 시 `farewellAvailableAt = now()` 즉시 예약 → `FarewellAvailabilityScheduler` → `NotificationService.sendTamagotchiFarewell` | userCharacterId (준비 완료된 ADULT) | 매분 cron, `farewell_available_at <= now`, `farewell_notified = false`, 활성/미삭제 대상. 플래그: `notification.farewell-available.enabled` |
| 다마고치 성장 | `TAMAGOTCHI_GROWTH` | `TamagotchiGrowthNotificationListener` | userCharacterId | 비활성화. HATCHED/EVOLVED 이벤트 리스너 Bean 은 유지하되 본문은 no-op |

다마고치 독립 승인(`TamagotchiServiceImpl.approveIndependence`)은 ADULT 검증 후 `farewellAvailableAt` 이 존재하고 현재 시각이 그 이후일 때만 통과한다. 기존 이별 시점 알림(`TamagotchiFarewellNotificationListener`)은 비활성화되어 새 EGG 생성 시 알림을 발송하지 않는다.

## 데이터 모델

- ERD 원본/도메인 매핑: [`erd.md`](erd.md)
- Redis 캐싱: [`caching.md`](caching.md)

## 관측성

액세스 로그 / 트랜잭션 타이밍 AOP / SQL 로깅 토글: [`observability.md`](observability.md)

## 환경/실행

- 로컬 부팅: [`../ops/run-local.md`](../ops/run-local.md)
- env 셋업: [`../ops/env-setup.md`](../ops/env-setup.md)
