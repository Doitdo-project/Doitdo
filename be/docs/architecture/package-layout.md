# 패키지 레이아웃 (package-layout)

`com.doitdo` 하위 구조와 신규 도메인 추가 시 따라야 할 5종 디렉토리 패턴.

## 베이스

```
com.doitdo
 ├ DoitdoApplication.java
 ├ domain/{도메인}/...
 └ global/...
```

## 도메인 패키지 — 5종 디렉토리 패턴 (Layered + DDD)

```
domain/{domain}/
 ├ api/
 │   ├ controller/                       # {Domain}Controller
 │   └ dto/
 │       ├ req/                          # {Action}{Domain}Req
 │       └ resp/                         # {Domain}Resp
 ├ application/
 │   ├ {Domain}Service.java              # interface
 │   └ impl/
 │       └ {Domain}ServiceImpl.java
 ├ entity/
 │   └ {Domain}.java                     # JPA Entity
 └ repository/
     └ {Domain}Repository.java           # Spring Data JPA
```

이 패턴은 **모든 도메인에서 동일**하다. 새 도메인 추가 시 이 골격을 그대로 복제한다.

## 등록된 도메인

`auth, user, todo, tamagotchi, inventory, shop, notification, setting, bugreport`

(노션 「엔드포인트」 카테고리 직역. 검색 기능은 `todo` 도메인 내부에서 처리.)

도메인 ↔ 테이블 매핑은 [`erd.md`](erd.md) 참고.

## global 패키지

공통 인프라. 모든 도메인이 의존할 수 있다.

```
global/
 ├ config/
 │   ├ SecurityConfig.java
 │   ├ JpaAuditingConfig.java
 │   ├ PasswordEncoderConfig.java
 │   └ OpenApiConfig.java                # springdoc-openapi 메타 + 11개 그룹 (auth, user, todo, tamagotchi, streak, inventory, shop, notification, setting, bugreport, global)
 ├ entity/
 │   └ BaseTimeEntity.java               # 공통 Auditing (createdAt/updatedAt)
 ├ exception/
 │   ├ ErrorCode.java                    # 인터페이스
 │   ├ ErrorCodeRegistry.java            # 10개 도메인 enum 정적 인덱스
 │   ├ CommonErrorCode.java              # G/G99
 │   ├ AuthErrorCode.java                # A
 │   ├ UserErrorCode.java                # U
 │   ├ TodoErrorCode.java                # T
 │   ├ TamagotchiErrorCode.java          # M
 │   ├ InventoryErrorCode.java           # I
 │   ├ ShopErrorCode.java                # S
 │   ├ NotificationErrorCode.java        # N
 │   ├ SettingErrorCode.java             # C
 │   ├ BugReportErrorCode.java           # B
 │   ├ CustomException.java
 │   └ GlobalExceptionHandler.java
 ├ swagger/                              # be/feat/swagger 머지 후 등장
 │   ├ ApiErrorCodes.java                # 메서드용 어노테이션
 │   ├ ApiErrorCodesCustomizer.java      # → Swagger 응답 자동 주입
 │   └ GlobalApiResponseCustomizer.java  # 모든 endpoint 500 G99-999 자동
 ├ api/response/
 │   └ GlobalApiResponse.java            # {status, code, message, data}
 ├ util/                                 # JwtUtil 등
 └ health/
     └ HealthController.java
```

## 새 도메인 추가 절차

1. 노션 「엔드포인트」 DB 카테고리에 신규 추가 합의되었는지 확인 (§2 SSOT).
2. `domain/{새도메인}/` 아래 5종 디렉토리 생성:
   - `api/controller/`
   - `api/dto/req/`
   - `api/dto/resp/`
   - `application/impl/`
   - `entity/`
   - `repository/`
3. ErrorCode enum 추가 (필요 시) — [`../api/error-codes.md`](../api/error-codes.md) 참고. 새 도메인 enum을 `ErrorCodeRegistry.SOURCES` 에 등록.
4. `OpenApiConfig` 에 `GroupedOpenApi` 빈 추가 (`packagesToScan` = 새 도메인의 `api.controller`).
5. ERD/매핑 표 갱신 — [`erd.md`](erd.md).

## todo 도메인 추가 파일 (snooze 이력)

| 종류 | 경로 | 비고 |
|---|---|---|
| Entity | `domain/todo/entity/SnoozeHistory.java` | `snooze_history` 테이블 매핑 |
| Repository | `domain/todo/repository/SnoozeHistoryRepository.java` | `countByTodoId`, `countByTodoIdIn` + `SnoozeCountProjection` |

`todos` 테이블 DDL 변경 없음. `snoozedDays` 는 COUNT 쿼리로 파생.

## todo 도메인 추가 파일 (카테고리 목록 조회 — T13)

| 종류 | 경로 | 비고 |
|---|---|---|
| Response DTO | `domain/todo/api/dto/resp/CategoryListResp.java` | `items[]` 래퍼, `CategoryResp::from` 스트림 |
| Repository | `domain/todo/repository/CategoryRepository.java` | `findAllByUserIdOrderByCategoryIdAsc(Long userId)` 추가 |

정렬 기준: `categoryId ASC` (JPA 메서드 네이밍 파생 쿼리).

## todo 도메인 추가 파일 (calendar / recurring MVP)

| 종류 | 경로 | 비고 |
|---|---|---|
| Request DTO | `domain/todo/api/dto/req/TodoCalendarReq.java` | `from/to/status/category/type` 캘린더 필터 |
| Request DTO | `domain/todo/api/dto/req/TodoSnoozeReq.java` | RECURRING snooze `occurrenceDate` body |
| Response DTO | `domain/todo/api/dto/resp/CalendarItemResp.java` | 실체/가상 캘린더 아이템 공통 응답 |
| Response DTO | `domain/todo/api/dto/resp/TodoCalendarResp.java` | `items[]` 래퍼 |
| Application util | `domain/todo/application/impl/CalendarOccurrenceGenerator.java` | RECURRING 마스터의 요청 기간 내 발생일 계산 (static util class, Spring Bean 아님) |
| Application interface | `domain/todo/application/RecurrenceService.java` | RECURRING TODO 캘린더 합성 + 실체화 인터페이스 |
| Application impl | `domain/todo/application/impl/RecurrenceServiceImpl.java` | RECURRING TODO 캘린더 합성 + 실체화 구현체 |
| Repository util | `domain/todo/repository/TodoSpecifications.java` | `overlappingRange(from, to)` 추가 |

`TodoServiceImpl` 은 CRUD + 속성 변경(status/priority/snooze) + 조회(list/search) 책임만 유지. RECURRING 관련 로직(캘린더 합성 + 가상 인스턴스 실체화)은 `RecurrenceService` 에 위임.

## todo-exp-system 추가 파일 (2026-04)

### 신규 패키지/파일

| 종류 | 경로 | 비고 |
|---|---|---|
| Domain Event | `domain/todo/event/TodoCompletedEvent.java` | TODO DONE 전이 시 발행되는 도메인 이벤트 record |
| Component | `domain/tamagotchi/application/ExpCalculator.java` | TODO 완료당 지급 exp (3~7 랜덤) 계산 컴포넌트 |
| Listener | `domain/tamagotchi/application/listener/TodoCompletionExpListener.java` | AFTER_COMMIT + REQUIRES_NEW 로 exp 가산 |
| Migration SQL | `docs/ops/migrations/2026-04-todo-exp-system.sql` | 수동 실행 필요 |
| Convention doc | `docs/conventions/domain-events.md` | 이벤트 네이밍/위치/TX 경계 컨벤션 |

### 패턴 확장 — 이벤트 패키지

```
domain/{domain}/
 ├ api/
 ├ application/
 │   ├ listener/             # 타 도메인 이벤트 구독 리스너 (이번 PR 최초 도입)
 │   └ ...
 ├ entity/
 ├ event/                    # 이 도메인에서 발행하는 도메인 이벤트 (이번 PR 최초 도입)
 └ repository/
```

도메인 이벤트 네이밍/트랜잭션 컨벤션은 [`../conventions/domain-events.md`](../conventions/domain-events.md) 참고.

## notification 도메인 구현 파일

| 종류 | 경로 | 비고 |
|---|---|---|
| Controller | `domain/notification/api/controller/NotificationController.java` | N02~N07 6개 엔드포인트 |
| Request DTO | `domain/notification/api/dto/req/DeviceTokenRegisterReq.java` | 토큰 등록 요청 |
| Request DTO | `domain/notification/api/dto/req/DeviceTokenUnregisterReq.java` | 토큰 해제 요청 |
| Response DTO | `domain/notification/api/dto/resp/DeviceTokenResp.java` | 등록된 디바이스 토큰 응답 |
| Response DTO | `domain/notification/api/dto/resp/NotificationResp.java` | 단일 알림 응답 |
| Response DTO | `domain/notification/api/dto/resp/NotificationListResp.java` | 목록 페이지 래퍼 |
| Response DTO | `domain/notification/api/dto/resp/NotificationReadResp.java` | 단일 읽음 처리 응답 |
| Response DTO | `domain/notification/api/dto/resp/NotificationReadAllResp.java` | 전체 읽음 처리 결과 |
| Application interface | `domain/notification/application/NotificationService.java` | 목록/읽음/삭제 인터페이스 |
| Application interface | `domain/notification/application/DeviceTokenService.java` | 토큰 등록/해제 인터페이스 |
| Application interface | `domain/notification/application/FcmService.java` | FCM 추상화 인터페이스 |
| Application impl | `domain/notification/application/impl/NotificationServiceImpl.java` | 알림 목록/읽음/삭제 구현 |
| Application impl | `domain/notification/application/impl/DeviceTokenServiceImpl.java` | 디바이스 토큰 upsert/비활성화 |
| Application impl | `domain/notification/application/impl/NoopFcmService.java` | 기본 활성 FCM 스텁 |
| Application impl | `domain/notification/application/impl/FirebaseFcmService.java` | `firebase.enabled=true` 시 실제 송신 |
| Scheduler | `domain/notification/application/scheduler/EveningReminderScheduler.java` | `NotificationSettingRepository` 존재 시에만 활성 |
| Scheduler | `domain/notification/application/scheduler/FarewellAvailabilityScheduler.java` | ADULT cap 도달 즉시 활성화된 독립 준비 완료 캐릭터에 `TAMAGOTCHI_FAREWELL` 발송 |
| Entity | `domain/notification/entity/Notification.java` | `notifications` 테이블 매핑 |
| Entity | `domain/notification/entity/DeviceToken.java` | 필드 유지, 등록/비활성화 메서드만 추가 |
| Repository | `domain/notification/repository/NotificationRepository.java` | 목록 조회 + 전체 읽음 벌크 업데이트 |
| Repository | `domain/notification/repository/DeviceTokenRepository.java` | FCM 토큰 조회 + 활성 토큰 목록 조회 |
| Config | `global/config/FirebaseConfig.java` | Firebase App/Messaging 조건부 등록 |

## todo 도메인 추가 파일 (alertTime 활성화 + FCM 알림 스케줄러)

| 종류 | 경로 | 비고 |
|---|---|---|
| Scheduler | `domain/notification/application/scheduler/TodoAlertScheduler.java` | 매 분 실행. `alert_time` 일치 TODO 에 개별 FCM 발송 |
| Repository 메서드 | `domain/todo/repository/TodoRepository.java` | `findAlertTargets(hhmm, today)` 추가 |

`alert_time` 컬럼은 이미 `todos` 테이블에 존재 (`VARCHAR(5)`, HH:mm 포맷). DDL 변경 없음.
`TodoCreateReq` / `TodoUpdateReq` 에 `alertTime` 필드 추가 (`@Pattern` 검증).
`TodoDetailResp` 에 `alertTime` 필드 추가 (리스트/검색 응답 자동 반영).
`Todo.create(...)` / `Todo.update(...)` 시그니처에 `alertTime` 파라미터 추가.

RECURRING 마스터 제외 규칙: 마스터 row 는 `type = RECURRING` 으로 저장되고, 실체화된 인스턴스는 `type = NORMAL` 로 저장됨(`Todo.createRecurringInstance` 참고). 쿼리 조건 `t.type <> RECURRING` 으로 마스터를 제외.

## todo 도메인 추가 파일 (alert/recurrence redesign — daysOfWeek + 실체화 스케줄러)

| 종류 | 경로 | 비고 |
|---|---|---|
| Scheduler | `domain/todo/application/scheduler/RecurrenceMaterializeScheduler.java` | RECURRING 마스터를 매일 자정 NORMAL 인스턴스로 실체화 (Asia/Seoul, idempotent via uk_todos_user_master_date) |
| Migration SQL | `docs/ops/migrations/2026-04-alert-recurrence-redesign.sql` | 수동 실행 필요. period 컬럼 삭제 + days_of_week 추가 + UNIQUE 제약 |

`period` 컬럼이 삭제되고 `days_of_week VARCHAR(27)` (CSV, 예: `"MON,WED,FRI"`) 로 교체됨. Entity/DTO/Generator/Service/Scheduler 모두 `daysOfWeek` 기반으로 교체.

UNIQUE 제약 `uk_todos_user_master_date (user_id, master_todo_id, start_date)` 추가 — 스케줄러/snooze 중복 INSERT 방지.

`TodoUpdateReq` 에 `Boolean clearAlertTime` 플래그 추가 — `true` 이면 `alertTime` 을 null 로 초기화 (alertTime 동시 전송 시 clear 우선).

## todo 도메인 추가 파일 (팔레트 조회 API + Category colorHex)

| 종류 | 경로 | 비고 |
|---|---|---|
| Response DTO | `domain/todo/api/dto/resp/PaletteResp.java` | `paletteId, paletteName, colors[]` |
| Application interface | `domain/todo/application/PaletteService.java` | `list()` |
| Application impl | `domain/todo/application/impl/PaletteServiceImpl.java` | PaletteColor 전체 1회 조회 후 paletteId 로 그룹핑 |
| Controller | `domain/todo/api/controller/PaletteController.java` | `GET /api/palettes` |

`CategoryResp` 에 `colorHex` 필드 추가 (`colorId` 유지). `CategoryServiceImpl` 이 `PaletteColorRepository` 를 주입받아 N+1 없이 hex 매핑.

## shop 도메인 구현 파일 (가구 상점 1차 MVP)

| 종류 | 경로 | 비고 |
|---|---|---|
| Controller | `domain/shop/api/controller/ShopController.java` | 가구 목록/구매/보유 목록 3개 엔드포인트 |
| Response DTO | `domain/shop/api/dto/resp/FurnitureShopResp.java` | 상점 가구 목록 래퍼 |
| Response DTO | `domain/shop/api/dto/resp/FurnitureShopItemResp.java` | 상점 가구 단일 응답, `owned/soldOut` 포함 |
| Response DTO | `domain/shop/api/dto/resp/PurchaseFurnitureResp.java` | 구매 결과, 잔액 포함 |
| Response DTO | `domain/shop/api/dto/resp/UserFurnitureResp.java` | 보유 가구 목록 래퍼 |
| Response DTO | `domain/shop/api/dto/resp/UserFurnitureItemResp.java` | 보유 가구 단일 응답 |
| Application interface | `domain/shop/application/ShopService.java` | 가구 목록/구매/보유 목록 인터페이스 |
| Application impl | `domain/shop/application/impl/ShopServiceImpl.java` | 월렛 차감 + 보유 생성 + 구매 로그 저장 |
| Entity | `domain/shop/entity/Furniture.java` | `furnitures` 테이블 매핑 |
| Entity | `domain/shop/entity/UserFurniture.java` | `user_furnitures` 테이블 매핑, `(user_id, furniture_id)` unique |
| Entity | `domain/shop/entity/FurniturePurchaseLog.java` | `furniture_purchase_logs` 테이블 매핑 |
| Repository | `domain/shop/repository/FurnitureRepository.java` | 가구 조회 |
| Repository | `domain/shop/repository/UserFurnitureRepository.java` | 보유 가구 조회/중복 확인 |
| Repository | `domain/shop/repository/FurniturePurchaseLogRepository.java` | 가구 구매 로그 |
| Migration SQL | `docs/ops/migrations/2026-05-shop-furniture.sql` | 수동 실행 필요 |

`UserWallet.spend(Integer amount)` 와 `UserWalletRepository.findByUserIdForUpdate(Long userId)` 로 구매 차감과 동시성 제어를 처리한다.

## bugreport 도메인 구현 파일

| 종류 | 경로 | 비고 |
|---|---|---|
| Controller | `domain/bugreport/api/controller/BugReportController.java` | `POST /api/bug-reports` 단일 엔드포인트, 201 Created |
| Request DTO | `domain/bugreport/api/dto/req/CreateBugReportReq.java` | `title`(@Size max=100) / `content`(@Size max=500) |
| Response DTO | `domain/bugreport/api/dto/resp/BugReportResp.java` | `bugReportId, createdAt` — `from(BugReport)` 팩토리 |
| Application interface | `domain/bugreport/application/BugReportService.java` | `create(Long userId, CreateBugReportReq req)` |
| Application impl | `domain/bugreport/application/impl/BugReportServiceImpl.java` | `@Transactional` save + DTO 변환 |
| Entity | `domain/bugreport/entity/BugReport.java` | `bug_reports` 테이블 매핑, inner enum `BugReportStatus(NEW/REVIEWING/COMPLETE)`, soft delete |
| Repository | `domain/bugreport/repository/BugReportRepository.java` | `JpaRepository<BugReport, Long>` (MVP: POST만) |
| Migration SQL | `docs/ops/migrations/2026-04-bug-report.sql` | 수동 실행 필요 |

`BugReportErrorCode` (`B` 접두, `global/exception/`) — `ErrorCodeRegistry.SOURCES` 에 등록.

## 네이밍/엔티티 규칙

상세는 [`../conventions/naming.md`](../conventions/naming.md). 요약:

- Controller / Service / Repository / Entity / DTO 명명 패턴 강제
- Entity 는 Lombok `@Getter @NoArgsConstructor(access=PROTECTED) @Builder @AllArgsConstructor(access=PRIVATE)`
- 생성/수정 시각이 둘 다 있는 엔티티는 `BaseTimeEntity` 상속
- FK는 `@ManyToOne` 대신 Long ID 필드 보관
