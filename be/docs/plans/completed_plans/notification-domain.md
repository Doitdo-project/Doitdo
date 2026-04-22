# Plan — 알림(Notification) 도메인 BE 기반 구축

## Context

왜 이 변경이 필요한가:
- Notion API 기본 명세서에 알림 관련 8개 API(N00~N07) 가 확정됐다. 이 중 6개(N02~N07) + FCM 인프라 + 저녁 리마인더 스케줄러가 내(김재환) 담당이다 — JIRA 스토리 **-345** / **-346** 및 표면 Task **-354/-355/-356**, 총 **하위작업 6 + 표면 Task 3**.
- 현재 BE 상태: `domain/notification/` 디렉토리 골격만 있고 컨트롤러·DTO·서비스·Repository 전부 `.gitkeep`. 엔티티는 `DeviceToken` 1개만 존재 (Notification 엔티티 자체가 없음).
- 현재 `NotificationErrorCode` 12개 항목은 "N00_xxx = 알림 목록 조회" 식으로 명세와 **prefix 의미가 불일치** — 명세 기준으로 전면 재정의 필요.
- Firebase 프로젝트가 팀 차원에서 아직 셋업되지 않았지만(파일 확인: `google-services.json`, `firebase_options.dart` 모두 없음), **"있다고 가정하고 Noop 스텁으로 기반만 다지는" 전략**을 사용자가 선택 — 실제 FCM 송신은 `firebase.enabled=true` 플래그로 나중에 on.

의도한 결과:
- Firebase 미확보 상태에서도 8개 이슈 중 7개(-356, -348~-351, -354, -355) 완전 구현 + 1개(-352) Noop 스텁으로 머지 가능 + 1개(-353) 스케줄러 골격까지 작동 (실제 송신만 로그).
- Firebase 확보 후에는 `FIREBASE_SERVICE_ACCOUNT_PATH`·`FIREBASE_PROJECT_ID` env 채우고 `firebase.enabled=true` 만 켜면 전체 파이프라인 가동.

---

## 범위 (이번 PR 에서 커버)

| JIRA | 커버 여부 | 내용 |
|------|-----------|------|
| **-356** NotificationErrorCode 재정의 | ✅ | N00~N07 전체 명세 기준 교체 (N00/N01 은 황예찬이 쓸 것이지만 enum 은 지금 깐다) |
| **-348** N04 목록 조회 | ✅ | GET `/api/notifications`, 페이지네이션 + isRead 필터 |
| **-349** N05 읽음 | ✅ | PATCH `/api/notifications/{id}/read` |
| **-350** N06 전체 읽음 | ✅ | PATCH `/api/notifications/read-all` |
| **-351** N07 삭제 | ✅ | DELETE `/api/notifications/{id}`, soft delete |
| **-354** N03 디바이스 토큰 등록 | ✅ | POST `/api/notifications/device-token`, 201 |
| **-355** N02 디바이스 토큰 해제 | ✅ | DELETE `/api/notifications/device-token`, 204 |
| **-352** Firebase SDK + FcmService | ✅ (스텁) | `firebase-admin` 의존성 + `FirebaseConfig` 조건부 빈 + `FcmService` 인터페이스 + `NoopFcmService` 기본 구현 + `FirebaseFcmService` 조건부 활성 |
| **-353** 저녁 리마인더 스케줄러 | ✅ (스케줄러 구동) | `@EnableScheduling` + `EveningReminderScheduler`, 실제 송신은 `FcmService` 에 위임 (Noop 시 로그) |

**범위 제외 (별도 티켓/나중)**:
- TODO-008 잠금 해제 알림 — 스펙 불명확, 별도 JIRA
- DND 시간대 스킵 시 "밀린 알림" 재전송 정책 — 별도 설계 필요
- Notification push 실패 시 재시도 큐 — MVP 이후
- 실제 Firebase Console 프로젝트 생성·서비스 계정 키 배치 — 팀 차원 작업
- 알림 설정 API (N00/N01) 구현 — 황예찬 담당

---

## 설계

### 1. Notification 엔티티 (신규)

**테이블명**: `notifications`

**필드**:
| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `notification_id` | BIGINT PK auto | | PK |
| `user_id` | BIGINT | NOT NULL, FK to users | 수신자 (Long 만 저장, 엔티티 매핑 X) |
| `type` | VARCHAR(30) | NOT NULL | enum STRING |
| `title` | VARCHAR(100) | NOT NULL | |
| `message` | VARCHAR(500) | NOT NULL | 본문 |
| `is_read` | BOOLEAN | NOT NULL, default false | 읽음 여부 |
| `is_deleted` | BOOLEAN | NOT NULL, default false | 소프트 삭제 |
| `reference_id` | BIGINT | NULL | 연관 도메인 PK (TODO 등, optional) |
| `read_at` | DATETIME | NULL | 읽음 시점 |
| `created_at` | DATETIME | NOT NULL | BaseTimeEntity |
| `updated_at` | DATETIME | NOT NULL | BaseTimeEntity |

**NotificationType enum**:
```java
public enum NotificationType {
  REMINDER_EVENING,    // 저녁 잔여 TODO 리마인더 (-353 에서 사용)
  REMINDER_MORNING,    // 아침 리마인더 (향후 확장)
  TODO_UNLOCK,         // 잠금해제 알림 (향후 확장, 현재 미구현)
  TAMAGOTCHI_FAREWELL  // 다마고치 이별 알림 (향후 확장)
}
```
→ 이번 PR 에서는 `REMINDER_EVENING` 만 실제 생성됨. 나머지는 enum 만 선언.

**삭제 전략**: `is_deleted=true` 로 soft delete (기존 Todo 컨벤션 `isDeleted` 일치). 조회·읽음 API 는 `isDeleted=false` 만 반환.

---

### 2. NotificationErrorCode 재정의 (명세 SSOT)

기존 12개 enum 교체. 최종 매핑:

| Code | HTTP | 의미 |
|------|------|------|
| **N00_001** | 401 | (설정 변경) 인증 실패 |
| **N00_002** | 422 | (설정 변경) 시간 형식 오류 (HH:mm 필수) |
| **N00_003** | 500 | (설정 변경) 서버 오류 |
| **N01_001** | 401 | (설정 조회) 인증 실패 |
| **N01_002** | 404 | (설정 조회) 알림 설정 없음 |
| **N01_003** | 500 | (설정 조회) 서버 오류 |
| **N02_001** | 401 | (토큰 해제) 인증 실패 |
| **N02_002** | 404 | (토큰 해제) 등록되지 않은 FCM 토큰 |
| **N02_003** | 500 | (토큰 해제) 서버 오류 |
| **N03_001** | 401 | (토큰 등록) 인증 실패 |
| **N03_002** | 422 | (토큰 등록) 필수 파라미터 누락 |
| **N03_003** | 500 | (토큰 등록) 서버 오류 |
| **N04_001** | 401 | (목록 조회) 인증 실패 |
| **N04_002** | 500 | (목록 조회) 서버 오류 |
| **N05_001** | 401 | (읽음) 인증 실패 |
| **N05_002** | 403 | (읽음) 타 사용자 알림 |
| **N05_003** | 404 | (읽음) 알림 없음 |
| **N05_004** | 500 | (읽음) 서버 오류 |
| **N06_001** | 401 | (전체 읽음) 인증 실패 |
| **N06_002** | 500 | (전체 읽음) 서버 오류 |
| **N07_001** | 401 | (삭제) 인증 실패 |
| **N07_002** | 403 | (삭제) 타 사용자 알림 |
| **N07_003** | 404 | (삭제) 알림 없음 |
| **N07_004** | 500 | (삭제) 서버 오류 |

- `ErrorCodeRegistry.SOURCES` 는 이미 등록됨 → 유지.
- **401/500 은 글로벌 예외 핸들러가 자동 생성**하므로 서비스에서 throw 할 필요 없음 (컨벤션 확인). enum 에는 보존해 Swagger 문서화용으로 사용.

---

### 3. FCM 조건부 패턴 (-352)

**의존성 추가** (`build.gradle`):
```gradle
implementation 'com.google.firebase:firebase-admin:9.2.0'
```

**application.yml**:
```yaml
firebase:
  enabled: ${firebase.enabled:false}
  service-account-path: ${firebase.service-account-path:}
  project-id: ${firebase.project-id:}
```

**`be/env/dev.env.example` · `prod.env.example`**:
```properties
# Firebase (optional — enable after project setup)
# firebase.enabled=false
# firebase.service-account-path=/etc/doitdo/firebase-service-account.json
# firebase.project-id=doitdo-xxxxx
```

**패키지**: `com.doitdo.global.config.FirebaseConfig`, `com.doitdo.domain.notification.application.FcmService` (인터페이스), `application/impl/FirebaseFcmService`, `application/impl/NoopFcmService`.

```java
// FirebaseConfig
@Configuration
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "true")
class FirebaseConfig {
  @Bean FirebaseApp firebaseApp(@Value("${firebase.service-account-path}") String path) throws IOException {
    GoogleCredentials creds = GoogleCredentials.fromStream(new FileInputStream(path));
    return FirebaseApp.initializeApp(FirebaseOptions.builder().setCredentials(creds).build());
  }
  @Bean FirebaseMessaging firebaseMessaging(FirebaseApp app) { return FirebaseMessaging.getInstance(app); }
}

// 인터페이스
public interface FcmService {
  SendResult send(List<DeviceToken> tokens, String title, String body);
  record SendResult(int successCount, List<Long> deactivatedTokenIds) {}
}

// 활성 구현
@Service
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "true")
@RequiredArgsConstructor
class FirebaseFcmService implements FcmService {
  private final FirebaseMessaging messaging;
  private final DeviceTokenRepository deviceTokenRepository;
  public SendResult send(...) { /* MulticastMessage + 실패 토큰 isActive=false */ }
}

// 스텁
@Service
@ConditionalOnProperty(name = "firebase.enabled", havingValue = "false", matchIfMissing = true)
@RequiredArgsConstructor
@Slf4j
class NoopFcmService implements FcmService {
  public SendResult send(List<DeviceToken> tokens, String title, String body) {
    log.info("[fcm-noop] would send to {} tokens: title='{}', body='{}'", tokens.size(), title, body);
    return new SendResult(tokens.size(), List.of());
  }
}
```

→ 스케줄러·이벤트 트리거는 항상 `FcmService.send(...)` 를 호출. Firebase off 면 로그만 찍힘 → 부팅/테스트 모두 통과.

---

### 4. 저녁 리마인더 스케줄러 (-353)

**패키지**: `com.doitdo.domain.notification.application.scheduler.EveningReminderScheduler`

**활성화**: `@EnableScheduling` 을 `com.doitdo.DoitdoApplication` 또는 별도 `@Configuration` 에 추가.

**로직 (의사코드)**:
```java
@Scheduled(cron = "0 * * * * *")   // 매 분 정각
public void run() {
  // 1. NotificationSetting 중 eveningEnabled=true 인 유저 조회
  //    (황예찬이 만들 엔티티 — 이번 PR 에서는 이 repository 가 없을 수도. 임시로 주석 처리 or "설정이 없는 유저는 기본값으로 간주" 정책 결정 필요)
  // 2. 현재 시각(HH:mm) 이 eveningTime 과 일치하는 유저만 필터
  // 3. 각 유저에 대해:
  //    - pushEnabled=false 또는 DND 구간이면 skip
  //    - 미완료 TODO 개수 조회 (TodoRepository.countByUserIdAndStatusNotAndIsDeletedFalse(...))
  //    - 0 이면 skip
  //    - Notification 엔티티 저장 (type=REMINDER_EVENING)
  //    - deviceTokens = DeviceTokenRepository.findAllByUserIdAndIsActiveTrue(userId)
  //    - fcmService.send(deviceTokens, title, body)
  //    - 실패 토큰은 send() 안에서 isActive=false 처리
}
```

**NotificationSetting 엔티티 의존성 문제**:
- 설정 도메인은 황예찬 담당이라 이번 PR 시점에는 없을 수 있음.
- **해결**: 이번 PR 에서는 스케줄러를 구현하되 NotificationSetting 조회 부분을 **"TODO 주석 + 전원 기본값(20:00, pushEnabled=true, DND 없음) 가정"** 으로 처리. 황예찬 PR 머지 후 후속 이슈로 연동.
- 또는: 스케줄러 `@ConditionalOnBean(NotificationSettingRepository.class)` 로 의존 빈 없으면 비활성화. → **후자 채택** (깔끔함).

---

### 5. 파일 구조 (새로 만들/수정할 파일)

```
be/src/main/java/com/doitdo/
├── DoitdoApplication.java                        (수정: @EnableScheduling 추가)
├── domain/notification/
│   ├── api/
│   │   ├── controller/
│   │   │   └── NotificationController.java       (신규, N02~N07 6개 엔드포인트)
│   │   └── dto/
│   │       ├── req/
│   │       │   ├── DeviceTokenRegisterReq.java   (신규, N03)
│   │       │   └── DeviceTokenUnregisterReq.java (신규, N02)
│   │       └── resp/
│   │           ├── NotificationResp.java         (신규, 단건)
│   │           ├── NotificationListResp.java     (신규, 목록 래퍼)
│   │           ├── NotificationReadResp.java     (신규, N05)
│   │           ├── NotificationReadAllResp.java  (신규, N06 { updatedCount })
│   │           └── DeviceTokenResp.java          (신규, N03)
│   ├── application/
│   │   ├── NotificationService.java              (신규, 인터페이스)
│   │   ├── DeviceTokenService.java               (신규, 인터페이스)
│   │   ├── FcmService.java                       (신규, 인터페이스)
│   │   ├── impl/
│   │   │   ├── NotificationServiceImpl.java      (신규)
│   │   │   ├── DeviceTokenServiceImpl.java       (신규)
│   │   │   ├── FirebaseFcmService.java           (신규, 조건부)
│   │   │   └── NoopFcmService.java               (신규, 기본)
│   │   └── scheduler/
│   │       └── EveningReminderScheduler.java     (신규, 조건부)
│   ├── entity/
│   │   ├── DeviceToken.java                      (기존, 수정 없음)
│   │   └── Notification.java                     (신규)
│   └── repository/
│       ├── DeviceTokenRepository.java            (신규)
│       └── NotificationRepository.java           (신규)
├── global/
│   ├── config/
│   │   └── FirebaseConfig.java                   (신규, 조건부)
│   └── exception/
│       └── NotificationErrorCode.java            (수정: N00~N07 전면 재정의)
└── ... (기존)

be/
├── build.gradle                                  (수정: firebase-admin 추가)
├── env/
│   ├── dev.env.example                           (수정: firebase.* placeholder 주석 추가)
│   └── prod.env.example                          (수정: firebase.* placeholder 주석 추가)
├── src/main/resources/
│   └── application.yml                           (수정: firebase.* 블록 추가)
└── docs/
    ├── api/error-codes.md                        (수정: N00~N07 재정의 반영)
    └── architecture/package-layout.md            (수정: notification 5종 디렉토리 체크리스트 업데이트 — 실제 구현으로 채워짐)
```

---

## 구현 순서 (단일 Codex 세션에서 차례로)

1. **NotificationErrorCode 재정의** (`global/exception/NotificationErrorCode.java`) — 위 테이블 그대로
2. **Notification 엔티티 + NotificationType enum** (`entity/Notification.java`) — BaseTimeEntity 상속, Lombok, 정적 팩토리 `of(...)`
3. **Repository 2개** — `NotificationRepository`(findAllByUserIdAndIsDeletedFalse + 페이지 + isRead 필터, `updateAllRead(Long userId)` @Modifying), `DeviceTokenRepository`(findByFcmToken, findAllByUserIdAndIsActiveTrue)
4. **DTO 7개** (위 파일 구조 참고, record 선호)
5. **Service 인터페이스·구현** — NotificationService, DeviceTokenService, FcmService + Noop/Firebase 구현
6. **FirebaseConfig** (`@ConditionalOnProperty`)
7. **NotificationController** — 6개 엔드포인트, `@AuthenticationPrincipal CustomUserDetails`, `@Operation` + `@ApiErrorCodes`, `GlobalApiResponse` 정적 팩토리 사용
8. **EveningReminderScheduler** (`@ConditionalOnBean(NotificationSettingRepository.class)` 로 설정 도메인 머지 전까지 비활성)
9. **DoitdoApplication 에 @EnableScheduling**
10. **build.gradle** — `firebase-admin:9.2.0` 추가
11. **application.yml / env/*.env.example** — firebase.* placeholder
12. **docs 갱신** — `docs/api/error-codes.md`, `docs/architecture/package-layout.md` (CLAUDE.md 의 "같은 PR 에서 docs 필수 갱신" 규칙 준수)

---

## 검증 (Codex 가 완료 후 Head 가 검증)

1. **컴파일**: `./gradlew compileJava` 성공
2. **단위/통합 테스트** (옵션, 이번 PR 에선 수작업 E2E 만 해도 OK):
   - `curl -X POST /api/notifications/device-token` 으로 N03 201 확인
   - `curl -X DELETE /api/notifications/device-token` 으로 N02 204 확인
   - 임의 Notification 레코드 삽입 후 `GET /api/notifications` 페이지네이션·isRead 필터 동작
   - `PATCH /.../read`, `/read-all`, `DELETE /...` 각각 정상/403(타인 소유)/404(없음) 시나리오
3. **Firebase off 동작**: 부팅 시 `FirebaseConfig` 빈 안 만들어지는지, `NoopFcmService` 가 주입되는지, 스케줄러가 `@ConditionalOnBean(NotificationSettingRepository.class)` 로 **skip** 되는지 로그 확인
4. **Swagger**: `/swagger-ui.html?group=notification` 에서 6개 엔드포인트 전부 Bearer + ErrorCode 노출 확인
5. **docs 동기**: `docs/api/error-codes.md` 의 N00~N07 표가 Notion 명세와 일치

---

## Codex 위임 시 주의 (메모리 룰 반영)

- `--write` 플래그 반드시 포함
- `--background` 로 job 제출 후 log tail 로 완료 감지
- CDP MCP 사용 금지 문구 프롬프트에 포함
- Codex 개입 시 `be/docs/logs/codex.txt` 생성, 완료 시 삭제
- 완료 후 이 plan 파일을 `be/docs/plans/completed_plans/` 로 이동
- 완료 후 Sonnet 에게 `curl` 로 E2E 테스트 위임 (구현 권한 없이 테스트만)
- 설계안 승인 요청이 Codex 에서 오면 Claude 가 직접 판단해 재개
