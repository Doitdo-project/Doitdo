# BE 코어 리뷰 결과

## 검토 요약
- 검토 파일 수: 219 (`be/src/main/**`, `.gitkeep` 제외)
- HIGH: 3건 / MEDIUM: 12건 / LOW: 4건
- 6축 커버리지: 보안 ✓ / 회귀 ✓ / 성능 ✓ / 동시성 ✓ / 리소스 ✓ / 에러 처리 ✓
- 검토 방식: `main...HEAD` 정적 diff/소스 분석만 수행. 빌드/테스트/브라우저/CDP 미사용.

## HIGH (반드시 머지 전 수정)
### [HIGH-1] prod도 기본값으로 Hibernate `ddl-auto:update`가 적용될 수 있음
- 파일: be/src/main/resources/application.yml:8
- 문제: base 설정이 `JPA_DDL_AUTO` 미설정 시 `update`로 동작하고, `application-prod.yml`에서 `ddl-auto`를 명시적으로 덮지 않는다.
- 영향: 운영 배포 시 Hibernate가 신규 엔티티/컬럼/제약을 자동 변경하려고 하며, 실패하거나 예상과 다른 스키마가 생성될 수 있다. 특히 이번 변경은 신규 엔티티가 많고 일부 유니크/락 전제가 코드에 있어 마이그레이션 안정성 리스크가 크다.
- 권장: prod는 `validate` 또는 `none`으로 고정하고, Flyway/Liquibase/운영 SQL로 테이블·인덱스·유니크 제약·초기 데이터를 명시적으로 관리한다. `JPA_DDL_AUTO` 누락 시 update가 되지 않도록 기본값을 제거한다.
- 근거: git diff hunk 발췌
```diff
+  jpa:
+    hibernate:
+      ddl-auto: ${JPA_DDL_AUTO:update}
+    show-sql: true
+    properties:
+      hibernate:
+        "[format_sql]": true
```

> **🔄 재검증 (2026-04-28) — (변경됨) 미성립 (단, yml hard fix 권장)**
>
> - **yml 자체 변경 없음**: `application.yml:8` `ddl-auto: ${JPA_DDL_AUTO:update}` 그대로, `application-prod.yml` 에 ddl-auto override 없음
> - **부분 방어**: `be/env/.env.prod.example:10` 에 `JPA_DDL_AUTO=validate` 명시 + 주석. dev 예제는 주석 처리
> - **잔존 위험**: 방어선이 `.env.prod` 준수에만 의존. yml hard 차단 부재. `JPA_DDL_AUTO` 누락/오타 시 update 적용. fail-fast 없음
> - **권장**: `application-prod.yml` 에 `spring.jpa.hibernate.ddl-auto: ${JPA_DDL_AUTO:validate}` 직접 명시 (1줄). 추가로 부팅 시 `JPA_DDL_AUTO` 값 검증 빈
> - **우선순위**: **P1**

### [HIGH-2] refresh token이 사용자당 1개라는 코드 전제와 DB 제약이 불일치함
- 파일: be/src/main/java/com/doitdo/domain/auth/entity/RefreshToken.java:23
- 문제: `RefreshTokenRepository.findByUserId()`는 단건을 전제로 하지만 `refresh_tokens.user_id`에 유니크 제약이 없다.
- 영향: 같은 사용자가 최초 로그인/소셜 로그인/토큰 재발급을 동시에 수행하면 `findByUserId -> save` 레이스로 여러 row가 생길 수 있다. 이후 `findByUserId`가 `NonUniqueResultException`으로 터져 로그인/refresh가 500이 되거나, 회전된 refresh token 검증이 불안정해진다.
- 권장: `user_id` 유니크 제약을 마이그레이션으로 추가하고, 저장 경로는 DB upsert 또는 pessimistic lock/재조회 기반으로 정리한다. 보안상 refresh token 원문 저장 대신 해시 저장도 같이 검토한다.
- 근거: git diff hunk 발췌
```diff
+@Table(name = "refresh_tokens")
+public class RefreshToken {
+	@Id
+	@GeneratedValue(strategy = GenerationType.IDENTITY)
+	@Column(name = "token_id")
+	private Long tokenId;
+
+	@Column(name = "user_id", nullable = false)
+	private Long userId;
```

> **🔄 재검증 (2026-04-28) — 성립 유지 (변화 없음)**
>
> - `local-init/00-schema-and-seed.sql:376~392` `refresh_tokens` 테이블에 UNIQUE 키 0
> - `RefreshToken.java:35~36` `@UniqueConstraint` / `unique=true` 없음
> - `RefreshTokenRepository.java:9` `Optional<RefreshToken> findByUserId(...)` — 결과 2건 시 `IncorrectResultSizeDataAccessException` 폭발
> - `AuthServiceImpl.java:175~183` & `OAuthServiceImpl.java:352~360` 의 `saveOrUpdateRefreshToken` check-then-act 패턴 race 방어 0. 두 서비스 코드 중복
> - hotfix `5dd9c43` / `47af472` / `db/hotfix/2026-04-23_auto_providers_unique.sql` 모두 `auto_providers` 전용 — refresh_tokens 미수정
> - **권장**: `ALTER TABLE refresh_tokens ADD UNIQUE KEY uk_rt_user_id (user_id)` + 엔티티 `@UniqueConstraint` + `saveOrUpdateRefreshToken` 을 upsert / `ON DUPLICATE KEY UPDATE` 전환 + 토큰 SHA-256 해시 저장
> - **우선순위**: **P1**

### [HIGH-3] 회원가입이 `characters` EGG 마스터 데이터에 의존하지만 main 리소스에 시드/마이그레이션이 없음
- 파일: be/src/main/java/com/doitdo/domain/auth/application/impl/AuthServiceImpl.java:84
- 문제: 일반 회원가입은 즉시 EGG `UserCharacter`를 만들며 `characters` 테이블의 EGG row를 필수로 요구한다. 그러나 `be/src/main`에서 확인되는 initializer는 palette만 넣고, character/action/background seed나 migration은 확인되지 않는다.
- 영향: 신규/초기화된 운영 DB 또는 main 통합 후 새 환경에서 EGG 마스터 데이터가 없으면 회원가입이 `U00_005`로 실패한다. 확인 필요: 운영 DB에 수동 seed가 이미 있고 배포 절차에 포함돼 있다면 리스크는 낮아진다.
- 권장: character, action, background 등 다마고치 마스터 데이터를 main 리소스의 검증 가능한 migration/initializer로 포함하거나, 부팅 시 필수 마스터 데이터 검증 후 명확히 fail-fast 한다.
- 근거: git diff hunk 발췌
```diff
+		// 회원가입 직후부터 exp 시스템 대상이 되도록 EGG UserCharacter 자동 생성.
+		Character eggCharacter = randomEggCharacter();
+		userCharacterRepository.save(UserCharacter.builder()
+				.userId(user.getUserId())
+				.characterId(eggCharacter.getCharacterId())
+				.name("뚜잇이")
+				.currentExp(0)
```

> **🔄 재검증 (2026-04-28) — 부분 성립 (자동 적용 미해결)**
>
> - **추가됨**: 커밋 `9cd7a92 chore: add MVP character seed SQL` 로 `be/docs/ops/migrations/2026-04-mvp-character-seed.sql` 추가 (DUCK/ELEPHANT/HALLABONG/RACCOON EGG 포함)
> - **그러나 자동 적용 X**: `docs/ops/migrations/` 위치 → Spring Boot 자동 로드 경로 아님. 수동 실행 전용
> - `DataInitializer.java:77~96` palette 만 처리, characters 초기화 0
> - `AuthServiceImpl.java:110~116` `randomEggCharacter()` — EGG 비면 `U00_005` 즉시 throw, graceful fallback 0
> - `application*.yml` 에 `spring.sql.init.*` 0, Flyway/Liquibase 미도입
> - `local-init/00-schema-and-seed.sql` 에 EGG row 있으나 git 추적 없음
> - 두 seed 파일(local-init id 26~32 vs MVP seed id 4~30) ID 범위 불일치 → SSOT 불명확
> - `be/docs/ops/deployment.md` 는 placeholder
> - **권장**: `DataInitializer.run()` 에 `countByStage(EGG) == 0` 시 INSERT-IGNORE 추가 + 부팅 시 EGG 검증 fail-fast. 중기 Flyway 도입 + `deployment.md` placeholder 갱신
> - **우선순위**: **P1**

## MEDIUM
### [MEDIUM-1] 반복 TODO 실체화 중복 방지가 DB 유니크 없이 동작함
- 파일: be/src/main/java/com/doitdo/domain/todo/application/scheduler/RecurrenceMaterializeScheduler.java:39
- 문제: 스케줄러/요청 경로가 `find -> save` 후 `DataIntegrityViolationException`으로 중복을 방어하려 하지만 `Todo` 엔티티에는 `(user_id, master_todo_id, start_date)` 유니크 제약이 없다.
- 영향: 멀티 인스턴스 스케줄러 또는 동시 snooze에서 같은 반복 발생일이 여러 TODO row로 생성될 수 있다. 이후 목록/캘린더/알림/완료 이벤트가 중복 처리된다.
- 권장: 반복 인스턴스 키에 DB 유니크 제약을 추가하고, 중복 예외 처리 경로가 실제로 작동하도록 한다. 운영 다중 인스턴스라면 ShedLock 등 분산 스케줄러 락도 검토한다.
- 근거: git diff hunk 발췌
```diff
+			if (todoRepository.findByUserIdAndMasterTodoIdAndStartDateAndIsDeletedFalse(
+					master.getUserId(), master.getTodoId(), today).isPresent()) {
+				skipped++;
+				continue;
+			}
+			try {
+				todoRepository.saveAndFlush(Todo.createRecurringInstance(master, today));
+				created++;
+			} catch (DataIntegrityViolationException ex) {
```

### [MEDIUM-2] 알림 스케줄러가 중복 실행/중복 발송에 대한 멱등성이 없음
- 파일: be/src/main/java/com/doitdo/domain/notification/application/scheduler/TodoAlertScheduler.java:27
- 문제: `@Scheduled`가 모든 인스턴스에서 매분 실행될 수 있고, 알림 row 저장 및 FCM 발송에 dedup key가 없다.
- 영향: 운영이 2개 이상 BE 인스턴스면 같은 분에 TODO 알림/아침/저녁 리마인더가 인스턴스 수만큼 저장·발송될 수 있다. 단일 인스턴스 운영이면 리스크는 낮다.
- 권장: 스케줄러 분산 락, 발송 이력 유니크 키(`notification_type`, `target_id`, `scheduled_minute`) 또는 idempotency table을 추가한다.
- 근거: git diff hunk 발췌
```diff
+	@Scheduled(cron = "0 * * * * *", zone = "Asia/Seoul")
+	public void run() {
+		ZonedDateTime now = ZonedDateTime.now(SEOUL);
+		String hhmm = now.format(HH_MM);
+		LocalDate today = now.toLocalDate();
+
+		List<Todo> targets = todoRepository.findAlertTargets(hhmm, today);
```

### [MEDIUM-3] TODO 완료 이벤트의 exp 지급 멱등성이 동시성에서 깨질 수 있음
- 파일: be/src/main/java/com/doitdo/domain/tamagotchi/application/listener/TodoCompletionExpListener.java:50
- 문제: `expGranted` 체크와 `markExpGranted()`가 별도 `REQUIRES_NEW` 트랜잭션에서 lock/version 없이 수행된다.
- 영향: 동일 TODO를 동시에 DONE 처리하면 두 요청이 모두 이벤트를 발행할 수 있고, 리스너도 둘 다 `expGranted=false`를 읽으면 경험치/알림이 중복될 수 있다. `UserCharacter` 갱신도 lost update 가능성이 있다.
- 권장: TODO 상태 변경 시 row lock 또는 optimistic `@Version`을 적용하고, exp 지급은 조건부 업데이트(`where exp_granted=false`) 결과가 1건일 때만 수행하도록 바꾼다.
- 근거: git diff hunk 발췌
```diff
+			if (Boolean.TRUE.equals(todo.getExpGranted())) {
+				log.debug("[exp] already granted; skipped todoId={}", event.todoId());
+				return;
+			}
+			UserCharacter uc = userCharacterRepository
+					.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(event.userId())
+					.orElse(null);
```

### [MEDIUM-4] 다마고치 독립 승인 동시 요청 시 활성 캐릭터가 여러 개 생길 수 있음
- 파일: be/src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java:360
- 문제: 활성 캐릭터 조회, 비활성화, 새 EGG 생성이 lock/unique constraint 없이 진행된다.
- 영향: 사용자가 버튼을 중복 탭하거나 재시도하면 두 트랜잭션이 같은 adult를 읽고 각각 새 active EGG를 만들 수 있다. 이후 `findFirstByUserIdAndIsActiveTrue...` 결과가 비결정적이 된다.
- 권장: 사용자 또는 active user_character row에 lock을 잡고, DB 레벨에서 사용자당 active+not-deleted 캐릭터 1개 제약을 둔다.
- 근거: git diff hunk 발췌
```diff
+			UserCharacter adultUserCharacter = userCharacterRepository
+				.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)
+				.orElseThrow(() -> new CustomException(TamagotchiErrorCode.M00_002));
+			adultUserCharacter.deactivate();
+			userCharacterRepository.save(adultUserCharacter);
+
+			UserCharacter nextEggCharacter = UserCharacter.builder()
+				.userId(userId)
```

### [MEDIUM-5] TODO 목록 조회가 페이지네이션 없이 전체 row를 메모리에 적재함
- 파일: be/src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java:90
- 문제: `GET /api/todos`가 필터 결과 전체를 `findAll(spec, sort)`로 가져오고, 이후 카테고리/스누즈 집계를 전체 ID set으로 다시 조회한다.
- 영향: 사용자의 TODO가 많거나 `view=all`, `q` 조합이 넓으면 응답 지연, 메모리 사용 증가, DB 부하가 커진다.
- 권장: 목록 API에도 page/size 상한을 도입하거나 날짜/view별 hard limit을 둔다. 기존 FE 호환이 필요하면 기본 limit과 next cursor를 추가한다.
- 근거: git diff hunk 발췌
```diff
+			Sort sort = resolveSort(req.sort());
+
+			List<Todo> todos = todoRepository.findAll(spec, sort);
+
+			// 카테고리 벌크 조회 (N+1 방지)
+			Set<Long> categoryIds = todos.stream()
+					.map(Todo::getCategoryId)
```

### [MEDIUM-6] 캘린더 조회 범위 제한이 없어 반복 occurrence를 무제한 생성할 수 있음
- 파일: be/src/main/java/com/doitdo/domain/todo/application/impl/CalendarOccurrenceGenerator.java:20
- 문제: `from/to` 유효성은 순서만 확인하고 최대 기간 제한이 없다. 반복 TODO마다 날짜를 하루씩 순회하며 `ArrayList`에 occurrence를 쌓는다.
- 영향: 악의적이거나 실수로 수년~수십년 범위를 요청하면 CPU/메모리 사용이 급증하고 응답이 느려진다.
- 권장: 캘린더 범위를 월 단위 또는 최대 31/62/366일 등으로 제한하고, 초과 시 명확한 4xx 에러를 반환한다.
- 근거: git diff hunk 발췌
```diff
+		List<LocalDate> occurrences = new ArrayList<>();
+
+		while (!cursor.isAfter(endBoundary)) {
+			if (daysOfWeek.contains(cursor.getDayOfWeek())) {
+				occurrences.add(cursor);
+			}
+			cursor = cursor.plusDays(1);
+		}
```

### [MEDIUM-7] Apple OAuth 응답 body가 토큰 포함 상태로 로그에 남을 수 있음
- 파일: be/src/main/java/com/doitdo/global/client/AppleOAuthClient.java:81
- 문제: Apple `/auth/token` 응답에서 refresh token이 없으면 전체 body를 error 로그에 출력한다. 응답 예시에는 access_token/id_token이 포함된다.
- 영향: Apple access token 또는 id_token이 운영 로그/로그 수집기에 남아 계정 식별 정보와 인증 자료가 노출될 수 있다.
- 권장: 외부 OAuth 응답 body는 로깅하지 말고 status/error code만 남긴다. 필요하면 토큰 필드를 마스킹한 구조화 로그로 제한한다.
- 근거: git diff hunk 발췌
```diff
+				JsonNode refresh = root.get("refresh_token");
+				if (refresh == null || refresh.asText().isBlank()) {
+					log.error("Apple /auth/token 응답에 refresh_token 누락: {}", body);
+					throw new CustomException(AuthErrorCode.A03_004);
+				}
+				return refresh.asText();
```

### [MEDIUM-8] prod에서 `/actuator/prometheus`가 인증 없이 열릴 수 있음
- 파일: be/src/main/java/com/doitdo/global/config/SecurityConfig.java:39
- 문제: SecurityConfig가 `/actuator/**`를 public으로 열고, prod 설정은 `health,info,prometheus`를 노출한다.
- 영향: API 서버가 인터넷에 직접 노출되어 있으면 JVM/HTTP/DB pool 등 운영 메트릭이 인증 없이 수집될 수 있다. 확인 필요: 별도 ingress/network ACL로 actuator가 막혀 있으면 리스크는 낮아진다.
- 권장: actuator는 별도 management port/network로 격리하거나 security matcher에서 health 정도만 public으로 제한한다. Prometheus는 내부망 또는 인증 뒤에 둔다.
- 근거: git diff hunk 발췌
```diff
+	private static final String[] PUBLIC_ENDPOINTS = {
+			"/hello",
+			"/db-check",
+			"/actuator/**",
+			"/api/auth/signup",
+			"/api/auth/login",
```

### [MEDIUM-9] 쿼리/모델 바인딩 오류가 도메인 ErrorCode 대신 500으로 떨어질 수 있음
- 파일: be/src/main/java/com/doitdo/global/exception/GlobalExceptionHandler.java:30
- 문제: `MethodArgumentNotValidException`과 JSON 파싱은 처리하지만, `@ModelAttribute` 날짜/enum 바인딩 오류나 `@RequestParam` type mismatch에 대한 `BindException`, `MethodArgumentTypeMismatchException` 처리가 없다.
- 영향: TODO list/calendar의 잘못된 날짜·enum 파라미터가 문서상 422가 아니라 전역 `Exception` 핸들러의 500으로 반환될 수 있다.
- 권장: `BindException`, `MethodArgumentTypeMismatchException`, `MissingServletRequestParameterException` 등을 `CommonErrorCode.VALIDATION_FAILED` 또는 도메인 ErrorCode로 변환한다.
- 근거: git diff hunk 발췌
```diff
+	@ExceptionHandler(MethodArgumentNotValidException.class)
+	public ResponseEntity<GlobalApiResponse<Void>> handleValidation(MethodArgumentNotValidException e) {
+		String message = e.getBindingResult().getFieldErrors().stream()
+			.map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
+			.collect(Collectors.joining(", "));
+		return ResponseEntity
```

### [MEDIUM-10] 소셜 신규 가입은 일반 회원가입과 달리 자동 EGG 캐릭터를 만들지 않음
- 파일: be/src/main/java/com/doitdo/domain/auth/application/impl/OAuthServiceImpl.java:150
- 문제: 일반 signup은 `UserCharacter` EGG를 생성하지만 Kakao/Google/Apple signup 경로는 wallet/setting/streak/category만 만들고 종료한다.
- 영향: 소셜 가입자가 온보딩 후 TODO를 완료해도 active `UserCharacter`가 없으면 exp 리스너가 skip한다. FE가 항상 `/api/characters/me/egg`를 호출한다는 보장이 없으면 가입 방식별 기능 차이가 생긴다.
- 권장: 일반/OAuth 공통 사용자 초기화 서비스를 만들고 EGG 생성까지 동일하게 처리한다. 이미 의도된 FE 플로우라면 API 계약에 명시한다.
- 근거: git diff hunk 발췌
```diff
+			User user = userRepository.save(User.createOAuthUser(email, username));
+			userWalletRepository.save(UserWallet.create(user.getUserId()));
+			userSettingRepository.save(UserSetting.create(user.getUserId()));
+			userStreakRepository.save(UserStreak.create(user.getUserId()));
+			autoProviderRepository.save(AutoProvider.create(user.getUserId(), providerName, providerUid));
+			defaultCategoryRegistrar.registerFor(user.getUserId());
+
+			return issueTokens(user, true);
```

### [MEDIUM-11] 검색/알림 페이지 size 상한이 없어 큰 페이지 요청으로 부하를 만들 수 있음
- 파일: be/src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java:325
- 문제: search는 `req.size()`를 그대로 `PageRequest`에 넘기고, 알림 목록은 `Math.max(size, 1)`만 적용해 상한이 없다.
- 영향: 큰 size 요청이 들어오면 DB/메모리/응답 payload가 커진다. 인증 API지만 사용자별 데이터가 쌓이면 쉽게 느려질 수 있다.
- 권장: size를 1~100 등으로 clamp하고 초과 요청은 400/422로 거절한다.
- 근거: git diff hunk 발췌
```diff
+			int page = req.page() != null ? req.page() : 0;
+			int size = req.size() != null ? req.size() : 20;
+			Sort sort = resolveSearchSort(sortParam);
+
+			// 페이지네이션 조회
+			Page<Todo> pageResult = todoRepository.findAll(spec, PageRequest.of(page, size, sort));
```

### [MEDIUM-12] SOMEDAY TODO snooze 시 NPE로 500이 발생할 수 있음
- 파일: be/src/main/java/com/doitdo/domain/todo/entity/Todo.java:114
- 문제: snooze API가 타입을 제한하지 않고, `Todo.snooze()`는 `startDate`가 null인 SOMEDAY TODO에서도 `plusDays`를 호출한다.
- 영향: 클라이언트가 SOMEDAY TODO를 미루면 도메인 ErrorCode가 아니라 서버 500이 발생한다.
- 권장: snooze 대상 타입/날짜를 서비스에서 검증하고, SOMEDAY는 4xx로 거절하거나 명시적 날짜 지정 플로우를 만든다.
- 근거: git diff hunk 발췌
```diff
+		public void snooze() {
+			this.startDate = this.startDate.plusDays(1);
+			if (this.endDate != null) {
+				this.endDate = this.endDate.plusDays(1);
+			}
+		}
```

## LOW
### [LOW-1] 인벤토리 조회에서 아이템 N+1 조회가 발생함
- 파일: be/src/main/java/com/doitdo/domain/inventory/application/impl/InventoryServiceImpl.java:42
- 문제: 사용자 아이템 목록을 가져온 뒤 각 itemId마다 `itemRepository.findById`를 호출한다.
- 영향: 보유 아이템 수가 늘면 인벤토리 API가 선형 DB round-trip을 만든다.
- 권장: `item_id in (...)` 벌크 조회 후 Map으로 조립하거나 repository join/projection을 사용한다.
- 근거: git diff hunk 발췌
```diff
+			List<InventoryItemResp> items = userItemRepository.findAllByUserId(userId).stream()
+				.map(userItem -> itemRepository.findById(userItem.getItemId())
+					.map(item -> new InventoryItemResp(
+						userItem.getUserItemId(),
+						item.getItemId(),
+						item.getCode(),
```

### [LOW-2] 카테고리 개수/이름 중복 제한이 애플리케이션 체크에만 의존함
- 파일: be/src/main/java/com/doitdo/domain/todo/application/impl/CategoryServiceImpl.java:36
- 문제: 사용자당 최대 6개와 이름 중복 검사가 `count/exists -> save`로만 구현되고 DB 제약이나 lock이 없다.
- 영향: 동시 생성 요청에서 6개 초과 또는 중복 이름이 들어갈 수 있다. 일반 사용 패턴에서는 낮은 확률이다.
- 권장: `(user_id, category_name)` 유니크 제약을 추가하고, 최대 개수는 사용자 row lock 또는 별도 quota 정책으로 방어한다.
- 근거: git diff hunk 발췌
```diff
+			if (categoryRepository.countByUserId(userId) >= MAX_CATEGORY_COUNT) {
+				throw new CustomException(TodoErrorCode.T10_003);
+			}
+
+			if (categoryRepository.existsByCategoryNameAndUserId(req.name(), userId)) {
+				throw new CustomException(TodoErrorCode.T10_004);
+			}
```

### [LOW-3] `PERIOD` TODO의 `endDate=null` 처리 기준이 API별로 다름
- 파일: be/src/main/java/com/doitdo/domain/todo/repository/TodoSpecifications.java:40
- 문제: calendar/alert 쿼리는 `endDate IS NULL`을 열린 기간으로 처리하지만 list `today` view는 `endDate >= baseDate`만 본다.
- 영향: endDate 없는 PERIOD TODO가 캘린더/알림에는 잡히고 목록 today에는 빠질 수 있다. 확인 필요: PERIOD의 endDate가 필수라는 정책이면 생성 검증을 추가해야 한다.
- 권장: PERIOD endDate nullable 정책을 확정하고 모든 조회 조건을 통일한다.
- 근거: git diff hunk 발췌
```diff
+						cb.and(
+								cb.equal(root.get("type"), TodoType.PERIOD),
+								cb.isNotNull(root.get("startDate")),
+								cb.lessThanOrEqualTo(root.get("startDate"), baseDate),
+								cb.greaterThanOrEqualTo(root.get("endDate"), baseDate)
+						)
```

### [LOW-4] Firebase 비활성 환경에서 알림 제목/본문이 info 로그에 남음
- 파일: be/src/main/java/com/doitdo/domain/notification/application/impl/NoopFcmService.java:22
- 문제: `firebase.enabled=false`일 때 FCM 대체 서비스가 알림 title/body를 그대로 info 로그에 남긴다.
- 영향: dev/local 로그에 TODO 제목이나 테스트 메시지 등 사용자 입력이 저장될 수 있다. prod에서 Firebase를 항상 켜면 영향은 제한적이다.
- 권장: 본문은 debug로 낮추거나 길이 제한/마스킹을 적용한다.
- 근거: git diff hunk 발췌
```diff
+	@Override
+	public SendResult send(List<DeviceToken> tokens, String title, String body) {
+		log.info("[fcm-noop] would send to {} tokens: title='{}', body='{}'", tokens.size(), title, body);
+		return new SendResult(tokens.size(), List.of());
+	}
```

## 검토한 주요 파일 (Top 30, 변경량 순)
- be/src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java (+465/-0)
- be/src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java (+436/-0)
- be/src/main/java/com/doitdo/domain/auth/application/impl/OAuthServiceImpl.java (+354/-0)
- be/src/main/java/com/doitdo/domain/todo/application/impl/RecurrenceServiceImpl.java (+276/-0)
- be/src/main/java/com/doitdo/domain/todo/entity/Todo.java (+242/-0)
- be/src/main/java/com/doitdo/domain/user/application/impl/UserServiceImpl.java (+237/-0)
- be/src/main/java/com/doitdo/domain/notification/application/impl/NotificationServiceImpl.java (+231/-0)
- be/src/main/java/com/doitdo/global/client/AppleIdTokenVerifierService.java (+195/-0)
- be/src/main/java/com/doitdo/domain/auth/application/impl/AuthServiceImpl.java (+174/-0)
- be/src/main/java/com/doitdo/global/util/AppleClientSecretGenerator.java (+153/-0)
- be/src/main/java/com/doitdo/domain/todo/api/controller/TodoController.java (+151/-0)
- be/src/main/java/com/doitdo/global/client/AppleOAuthClient.java (+132/-0)
- be/src/main/java/com/doitdo/domain/todo/application/impl/CategoryServiceImpl.java (+129/-0)
- be/src/main/java/com/doitdo/domain/todo/repository/TodoSpecifications.java (+128/-0)
- be/src/main/java/com/doitdo/domain/tamagotchi/api/controller/TamagotchiController.java (+124/-0)
- be/src/main/java/com/doitdo/domain/notification/api/controller/NotificationController.java (+120/-0)
- be/src/main/java/com/doitdo/global/config/OpenApiConfig.java (+114/-0)
- be/src/main/java/com/doitdo/domain/user/entity/User.java (+109/-0)
- be/src/main/java/com/doitdo/domain/inventory/application/impl/InventoryServiceImpl.java (+109/-0)
- be/src/main/java/com/doitdo/domain/setting/entity/UserSetting.java (+106/-0)
- be/src/main/java/com/doitdo/domain/streak/entity/UserStreak.java (+103/-0)
- be/src/main/java/com/doitdo/global/exception/TodoErrorCode.java (+100/-0)
- be/src/main/java/com/doitdo/domain/user/application/impl/UserHardDeleteService.java (+100/-0)
- be/src/main/java/com/doitdo/domain/auth/entity/AutoProvider.java (+98/-0)
- be/src/main/java/com/doitdo/global/config/DataInitializer.java (+97/-0)
- be/src/main/java/com/doitdo/domain/notification/entity/Notification.java (+96/-0)
- be/src/main/java/com/doitdo/domain/user/api/controller/UserController.java (+95/-0)
- be/src/main/java/com/doitdo/global/security/OnboardingRequiredFilter.java (+94/-0)
- be/src/main/java/com/doitdo/global/config/SecurityConfig.java (+91/-0)
- be/src/main/java/com/doitdo/domain/tamagotchi/entity/UserCharacter.java (+87/-0)
