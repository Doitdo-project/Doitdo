# BE 테스트 리뷰 결과

## 검토 요약
- 검토 파일 수: 30
- HIGH: 2건 / MEDIUM: 4건 / LOW: 3건
- 5축 커버리지: 테스트 신뢰성 ✓ / 커버리지 사각지대 ✓ / mocking 위생 ✓ / 리소스·격리 ✓ / 회귀 안전망 적합성 ✓
- 기준: `git diff main...HEAD -- 'be/src/test/'`
- 제약 준수: 빌드/테스트 미실행, BE main/FE/AI 미검토, CDP MCP 미사용

## HIGH (반드시 머지 전 수정)

### [HIGH-1] 생년월일 경계 테스트가 2026-04-28부터 의미가 바뀌는 날짜 의존 테스트다
- 파일: `be/src/test/java/com/doitdo/domain/user/application/impl/UserServiceImplOnboardingTest.java:50`
- 문제: 만 14세 경계값을 "오늘(2026-04-27)"에 하드코딩했다. 서비스가 시스템 날짜 기준으로 나이를 계산한다면, `2012-04-28`은 2026-04-27에는 만 13세지만 2026-04-28부터 만 14세가 되어 실패 기대값이 뒤집힌다.
- 영향: 브랜치 작성일 다음 날부터 `registerBirthDate_underAge14_throws_U00_006_and_userDeleted`가 실패하거나, 반대로 구현 회귀를 잘못 통과시키는 시간 의존 테스트가 된다. CI 실행일/타임존에 따라 결과가 달라질 수 있다.
- 권장: 나이 계산 기준일을 `Clock`/테스트용 now provider로 고정하거나, 테스트에서 현재 날짜를 주입할 수 있게 만든 뒤 `기준일`, `기준일.minusYears(14)`, `기준일.minusYears(14).plusDays(1)` 형태로 경계값을 생성한다. 서비스 변경 여부는 BE main 리뷰 범위라 여기서는 확인 필요.
- 근거:
```diff
@@ -50,0 +50,10 @@
+        // 오늘(2026-04-27) 기준 만 14세: 2012-04-27 생일
+        LocalDate birthDate = LocalDate.of(2012, 4, 27);
+        UserInfoResp resp = userService.registerBirthDate(userId, new RegisterBirthDateReq(birthDate));
+        ...
+        // 오늘(2026-04-27) 기준 만 13세: 2012-04-28 생일 (생일 아직 안 지남)
+        LocalDate underageBirthDate = LocalDate.of(2012, 4, 28);
+        assertThatThrownBy(() ->
+                userService.registerBirthDate(userId, new RegisterBirthDateReq(underageBirthDate))
+        )
```

### [HIGH-2] 테스트 리소스에 private key PEM 블록이 커밋됐다
- 파일: `be/src/test/resources/apple-test-key.p8:1`
- 문제: `-----BEGIN PRIVATE KEY-----` 형식의 개인키가 테스트 리소스에 추가됐다. `AppleClientSecretGeneratorTest`는 이미 `@TempDir`에서 EC 키를 즉석 생성하므로 이 파일은 테스트에 필요하지 않은 것으로 보인다.
- 영향: 더미 키인지 확인 필요하지만, 실제 Apple Sign in `.p8`였거나 재사용 가능한 개인키라면 저장소 노출 즉시 폐기/회전 대상이다. 더미 키라도 secret scanner와 운영자의 경보 피로를 유발한다.
- 권장: 파일을 제거하고 현재 테스트처럼 임시 키 생성만 사용한다. 이미 외부 원격에 push됐다면 더미 여부를 기록하고, 실제 키 가능성이 있으면 즉시 revoke/rotate한다.
- 근거:
```diff
@@ -0,0 +1,5 @@
+-----BEGIN PRIVATE KEY-----
+[REDACTED TEST PRIVATE KEY MATERIAL]
+[REDACTED TEST PRIVATE KEY MATERIAL]
+[REDACTED TEST PRIVATE KEY MATERIAL]
+-----END PRIVATE KEY-----
```

## MEDIUM

### [MEDIUM-1] `@SpringBootTest` DB 쓰기 테스트가 롤백 없이 실행되고 cleanup도 불완전하다
- 파일: `be/src/test/java/com/doitdo/domain/user/application/impl/UserServiceImplWithdrawTest.java:23`
- 문제: `@Transactional`을 일부러 걸지 않는 의도는 타당할 수 있으나, `UserServiceImplWithdrawTest`는 생성한 유저 row를 정리하지 않는다. `UserServiceImplOnboardingTest`도 `deleteById`가 assertion 뒤에 있어 중간 실패 시 row가 남는다.
- 영향: test profile DB가 persistent DB이거나 테스트가 병렬/반복 실행되면 데이터가 누적된다. `System.currentTimeMillis()` 기반 unique 값은 충돌 가능성을 낮출 뿐 cleanup을 대체하지 못한다. 실패한 테스트가 다음 테스트의 전제조건을 오염시킬 수 있다.
- 권장: 서비스 트랜잭션 검증은 유지하되 `@AfterEach`/`try-finally`/`@Sql` cleanup을 추가한다. L1 캐시 회귀를 잡아야 하는 테스트는 `TransactionTemplate` 또는 repository `flush/clear` 방식으로 검증하고, 생성 ID 목록을 추적해 항상 삭제한다.
- 근거:
```diff
@@ -23,0 +23,14 @@
+     * <p>테스트 메서드에 @Transactional 을 걸지 않는다.
+     * 이유: 테스트가 서비스 TX 에 참가하면 L1 캐시를 공유하여 SELECT 없이 캐시에서 읽어
+     * 버그를 탐지하지 못한다. 커밋 후 신규 조회로 실제 DB 상태를 확인한다.
+     */
+@ActiveProfiles("test")
+@SpringBootTest
+class UserServiceImplWithdrawTest {
+    ...
+    @Test
+    void withdraw_isDeletedTrue_persistedToDB() {
+        User saved = userRepository.save(
+                User.create(
+                        "withdraw-test-" + System.currentTimeMillis() + "@e2e.local",
```

### [MEDIUM-2] API controller 테스트 대부분이 Spring MVC 레이어를 우회한다
- 파일: `be/src/test/java/com/doitdo/domain/tamagotchi/api/controller/TamagotchiControllerTest.java:29`
- 문제: 컨트롤러를 직접 생성하고 `CustomUserDetails`도 직접 넘긴다. 따라서 URL mapping, HTTP method, path variable binding, request body validation, `@AuthenticationPrincipal`, Spring Security 설정 회귀를 잡지 못한다.
- 영향: 실제 API 경로가 깨지거나 DTO validation이 누락되어도 단위 호출 테스트는 계속 통과할 수 있다. 특히 이 변경분에는 다마고치/인벤토리/알림 controller 테스트가 같은 패턴이다.
- 권장: 최소 대표 경로는 `@WebMvcTest` 또는 `MockMvc` standalone + argument resolver/security 설정으로 HTTP 요청을 검증한다. 직접 호출 테스트를 유지하더라도 API contract 회귀 방지용 web slice 테스트를 별도로 둔다.
- 근거:
```diff
@@ -29,0 +29,12 @@
+@ExtendWith(MockitoExtension.class)
+class TamagotchiControllerTest {
+
+    @Mock
+    private TamagotchiService tamagotchiService;
+
+    @Test
+    void receiveEggReturnsGlobalApiResponse() {
+        TamagotchiController controller = new TamagotchiController(tamagotchiService);
+        CustomUserDetails userDetails = new CustomUserDetails(User.builder()
+            .userId(1L)
+            .email("user@example.com")
```

### [MEDIUM-3] 아이템 해제 controller 테스트가 서비스 호출을 검증하지 않는다
- 파일: `be/src/test/java/com/doitdo/domain/inventory/api/controller/InventoryUnequipItemControllerTest.java:31`
- 문제: `inventoryService` mock을 주입하지만 `controller.unequipItem(...)` 호출 후 서비스가 호출됐는지 검증하지 않는다. 응답 객체만 고정으로 만들면 테스트가 통과한다.
- 영향: 컨트롤러가 실제 해제 로직 호출을 누락해도 status/message/data assertion은 그대로 통과할 수 있어 회귀 안전망이 약하다.
- 권장: `then(inventoryService).should().unequipItem(1L, 10L, 42L);`를 추가하고, 필요하면 `shouldHaveNoMoreInteractions()`로 잘못된 추가 호출도 제한한다.
- 근거:
```diff
@@ -31,0 +31,6 @@
+            GlobalApiResponse<Void> resp = controller.unequipItem(userDetails, 10L, 42L);
+
+            assertThat(resp.getStatus()).isEqualTo(204);
+            assertThat(resp.getMessage()).isEqualTo("아이템 해제 완료");
+            assertThat(resp.getData()).isNull();
+        }
```

### [MEDIUM-4] 알림 listener 테스트의 mock이 SUT에 연결되지 않아 항상 통과하는 assertion이다
- 파일: `be/src/test/java/com/doitdo/domain/notification/application/listener/TodoCompletedNotificationListenerTest.java:15`
- 문제: `todoRepository` mock을 선언하지만 `TodoCompletedNotificationListener` 생성자에 주입하지 않는다. 마지막 assertion은 listener가 접근할 수 없는 mock의 무상호작용만 확인한다.
- 영향: listener가 실제로 알림을 보내도록 바뀌거나 이벤트 처리 부작용이 생겨도 이 테스트는 그 동작을 검증하지 못한다. "알림을 보내지 않는다"는 의도를 보호하지 못하는 false-positive 테스트다.
- 권장: listener의 실제 collaborator를 주입해 `notificationService/fcmService` 호출 여부를 검증하거나, 아직 동작이 없는 placeholder라면 테스트를 제거하고 실제 요구사항이 생길 때 의미 있는 collaborator 검증으로 추가한다.
- 근거:
```diff
@@ -15,0 +15,10 @@
+    @Mock
+    private TodoRepository todoRepository;
+
+    @Test
+    void onTodoCompletedDoesNotSendNotification() {
+        TodoCompletedNotificationListener listener = new TodoCompletedNotificationListener();
+
+        listener.onTodoCompleted(new TodoCompletedEvent(1L, 10L));
+
+        then(todoRepository).shouldHaveNoInteractions();
```

## LOW

### [LOW-1] `ExpCalculator` 테스트가 랜덤 구현을 직접 1000회 호출해 비결정적이고 의도 검증이 약하다
- 파일: `be/src/test/java/com/doitdo/domain/tamagotchi/application/ExpCalculatorTest.java:11`
- 문제: 랜덤 값을 직접 반복 호출해 범위만 확인한다. 현재 assertion은 `항상 3만 반환`, `항상 7만 반환` 같은 회귀도 통과시킨다.
- 영향: 테스트가 느리지는 않지만 랜덤성의 의도(분포, inclusive boundary, seed 안정성)를 보호하지 못한다. 랜덤 구현 변경 시 실패 재현성도 낮다.
- 권장: `Random`/`IntSupplier`를 주입 가능하게 만들고 seed 또는 fake generator로 하한/상한/중간값을 결정적으로 검증한다. 단순 smoke test로 유지한다면 이름을 "range smoke"로 낮춘다.
- 근거:
```diff
@@ -11,0 +11,8 @@
+    @Test
+    void rollTodoDoneExpAlwaysReturnsValueBetween3And7() {
+        for (int i = 0; i < 1000; i++) {
+            int result = calculator.rollTodoDoneExp();
+            assertThat(result)
+                    .isGreaterThanOrEqualTo(3)
+                    .isLessThanOrEqualTo(7);
+        }
```

### [LOW-2] 회원가입 랜덤 알 지급 테스트가 단일 fixture만 써서 랜덤/예외 경로를 보호하지 못한다
- 파일: `be/src/test/java/com/doitdo/domain/auth/application/impl/AuthServiceImplTest.java:96`
- 문제: 테스트명은 random egg assignment를 말하지만 `findAllByStage(EGG)`가 egg 1개만 반환한다. 여러 알 중 선택, 알 목록이 비었을 때의 실패 경로, 저장되는 이름/species 등 부가 상태는 검증하지 않는다.
- 영향: 구현이 항상 첫 번째만 선택하거나 빈 목록 처리를 잘못해도 현재 테스트는 happy path 일부만 보호한다.
- 권장: random 자체가 비즈니스 요구라면 deterministic random provider를 주입해 여러 후보 선택을 검증한다. 빈 egg 목록에 대한 exception/error code도 별도 테스트로 고정한다.
- 근거:
```diff
@@ -96,0 +96,10 @@
+    @Test
+    void signupAssignsRandomEggCharacter() {
+        AuthServiceImpl service = buildService();
+        ...
+        given(userRepository.save(any(User.class))).willReturn(savedUser);
+        given(characterRepository.findAllByStage(Character.Stage.EGG)).willReturn(List.of(defaultEggCharacter()));
+
+        SignupResp resp = service.signup(new SignupReq("user@example.com", "password123", "user"));
+        ...
+        assertThat(captor.getValue().getCharacterId()).isEqualTo(26L);
```

### [LOW-3] `TodoCompletionExpListenerTest` fixture에 사용되지 않는 파라미터/무의미한 assertion이 남아 있다
- 파일: `be/src/test/java/com/doitdo/domain/tamagotchi/application/listener/TodoCompletionExpListenerTest.java:47`
- 문제: `buildTodo(Long todoId, ...)`가 `todoId`를 받지만 builder에 반영하지 않는다. `skipsWhenAlreadyGranted`는 listener에 연결되지 않은 `uc`를 만들고, 그 값이 그대로인지만 확인한다.
- 영향: fixture가 테스트 의도를 흐리고, 나중에 todoId 기반 로직이 추가될 때 잘못된 테스트 데이터를 만들 수 있다. 현재 핵심 검증은 `verify(userCharacterRepository, never())`라서 `uc` assertion은 중복/오해 소지가 있다.
- 권장: `todoId`를 실제 builder에 넣거나 파라미터를 제거한다. 연결되지 않은 `uc`와 assertion은 제거하고, skip 경로에서 `expCalculator`/`characterRepository`도 호출되지 않는지 명확히 검증한다.
- 근거:
```diff
@@ -47,0 +47,13 @@
+    private Todo buildTodo(Long todoId, boolean expGranted) {
+        return Todo.builder()
+                .userId(1L)
+                .categoryId(null)
+                .title("test")
+                ...
+                .expGranted(expGranted)
+                .build();
+    }
+    ...
+        UserCharacter uc = buildUc(50);
+        ...
+        assertThat(uc.getCurrentExp()).isEqualTo(50);
```

## 검토한 주요 파일 (Top 30, 변경량 순)
- `be/src/test/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImplTest.java` (+688/-0)
- `be/src/test/java/com/doitdo/domain/tamagotchi/api/controller/TamagotchiControllerTest.java` (+222/-0)
- `be/src/test/java/com/doitdo/domain/user/application/impl/UserServiceImplOnboardingTest.java` (+205/-0)
- `be/src/test/java/com/doitdo/domain/tamagotchi/application/listener/TodoCompletionExpListenerTest.java` (+168/-0)
- `be/src/test/java/com/doitdo/global/security/OnboardingRequiredFilterTest.java` (+165/-0)
- `be/src/test/java/com/doitdo/domain/todo/application/impl/TodoServiceImplTest.java` (+162/-0)
- `be/src/test/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiEncyclopediaDetailServiceTest.java` (+135/-0)
- `be/src/test/java/com/doitdo/domain/user/application/impl/UserServiceImplWithdrawTest.java` (+132/-0)
- `be/src/test/java/com/doitdo/domain/streak/application/impl/UserStreakServiceImplRewardTest.java` (+127/-0)
- `be/src/test/java/com/doitdo/domain/auth/application/impl/AuthServiceImplTest.java` (+122/-0)
- `be/src/test/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiCurrentCharacterServiceImplTest.java` (+102/-0)
- `be/src/test/java/com/doitdo/global/util/AppleClientSecretGeneratorTest.java` (+98/-0)
- `be/src/test/java/com/doitdo/global/exception/ErrorCodeRegistryTest.java` (+96/-0)
- `be/src/test/java/com/doitdo/domain/inventory/application/impl/InventoryEquipItemServiceTest.java` (+91/-0)
- `be/src/test/java/com/doitdo/domain/notification/application/impl/NotificationServiceImplTest.java` (+91/-0)
- `be/src/test/java/com/doitdo/domain/tamagotchi/repository/UserCharacterRepositoryTest.java` (+88/-0)
- `be/src/test/java/com/doitdo/domain/inventory/application/impl/InventoryServiceImplTest.java` (+84/-0)
- `be/src/test/java/com/doitdo/domain/todo/application/scheduler/RecurrenceMaterializeSchedulerTest.java` (+79/-0)
- `be/src/test/java/com/doitdo/domain/inventory/application/impl/InventoryUnequipItemServiceTest.java` (+68/-0)
- `be/src/test/java/com/doitdo/domain/todo/application/impl/CalendarOccurrenceGeneratorTest.java` (+63/-0)
- `be/src/test/java/com/doitdo/global/health/HealthControllerWebMvcTest.java` (+63/-0)
- `be/src/test/java/com/doitdo/domain/inventory/api/controller/InventoryControllerTest.java` (+58/-0)
- `be/src/test/java/com/doitdo/domain/tamagotchi/api/controller/TamagotchiCurrentCharacterControllerTest.java` (+55/-0)
- `be/src/test/java/com/doitdo/domain/inventory/api/controller/InventoryEquipItemControllerTest.java` (+43/-0)
- `be/src/test/java/com/doitdo/domain/notification/api/controller/NotificationControllerTest.java` (+41/-0)
- `be/src/test/java/com/doitdo/domain/inventory/api/controller/InventoryUnequipItemControllerTest.java` (+37/-0)
- `be/src/test/java/com/doitdo/domain/notification/application/listener/TodoCompletedNotificationListenerTest.java` (+26/-0)
- `be/src/test/java/com/doitdo/domain/tamagotchi/application/ExpCalculatorTest.java` (+20/-0)
- `be/src/test/java/com/doitdo/DoitdoApplicationTests.java` (+15/-0)
- `be/src/test/resources/apple-test-key.p8` (+5/-0)
