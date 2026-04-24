# Plan — TODO 완료 연동 경험치 시스템 (Exp System)

> **작성자**: 김재환 (Claude Opus 4.7, Head) 설계
> **구현 위임 대상**: Sonnet 서브에이전트
> **JIRA 스토리 후보 제목**: "사용자는 TODO 를 완료하며 경험치를 쌓아 다마고치를 키우고 싶다"
> **타겟 브랜치**: `be/feat/todo-exp-system` (신설, `dev` 기준)
> **연관 API 문서(Notion)**: [TODO 상태 변경 (T03)](https://www.notion.so/TODO-3428ab5fe9a9819892c9e0e942322f94) — 이미 exp 연동 부수효과 기록 완료

---

## 1. 배경 및 목적

현재 BE 의 `/evolution` API 는 경험치 게이팅 없이 무조건 통과하고, `UserCharacter.growthPercent` 컬럼은 `0` 으로만 세팅되며 증가 경로가 전혀 없다. `TodoServiceImpl.changeStatus()` 에 `// TODO: Tamagotchi 이벤트 발행 추가 예정` 주석만 남아있는 상태.

이 스토리에서:
- TODO 완료(`DONE` 전이) 시 Tamagotchi 경험치가 실제로 증가하도록 연동
- Character 별 단계 이동에 필요한 `required_exp` 를 DB 컬럼으로 분리 (하드코딩 제거)
- `UserCharacter.current_exp` 컬럼으로 누적 exp 저장, `growth_percent` 는 파생 계산으로 전환
- `/evolution` 에 exp 게이팅 추가
- ADULT 단계에서 exp 충족 시 `canFarewell` 플래그 노출
- Todo 완료 반복 어뷰징 방지를 위해 `Todo.exp_granted` 1회성 지급 플래그 추가
- 회원가입 시 EGG UserCharacter 자동 생성 — 회원가입 ~ `/start` 공백 구간 제거

---

## 2. 확정된 설계 요약

| 항목 | 결정 | 근거 |
|------|------|------|
| 스키마 변경 | `characters.required_exp`, `user_character.current_exp`, `todos.exp_granted` 추가 / `user_character.growth_percent` 제거 | FE 가 growthPercent 미사용 (`fe/doitdo/lib/presentation/pages/tamagochi/tamagochi_state.dart` 의 `currentExp / expToNextLevel` 자체 계산 확인) |
| 단계별 `required_exp` | EGG=0, BABY=100, TEEN=200, ADULT=300 | 사용자 확정. 차등은 이 값으로만 |
| 건당 지급 | **3~7 랜덤** (전 단계 공통) | 사용자 확정. 평균 5 → 졸업까지 평균 120건 |
| Cap | `Math.min(requiredExp, currentExp + delta)` 전 단계 | 사용자 확정 |
| 진화 게이팅 | `/evolution` 에서 `currentExp >= requiredExp` 체크, 부족 시 M05_006 | 사용자 확정 |
| Farewell | 플래그(`canFarewell`)만 응답에 노출, 강제 안 함 | 사용자 확정 |
| `canFarewell`/`canEvolve` | DB 컬럼 아님. Response 파생 필드 | DB 저장 시 sync bug 리스크 회피 |
| Farming 방어 | `Todo.exp_granted BOOLEAN`, 생애 1회만 지급. 리스너가 멱등성 체크 | 사용자 확정. 같은 Todo 왕복 100% 차단 |
| 이벤트 방식 | `TodoCompletedEvent` + `@TransactionalEventListener(AFTER_COMMIT)` + `@Transactional(REQUIRES_NEW)` | 도메인 결합 느슨, TX 경계 분리, Todo DONE 저장 커밋 후 exp 가산 |
| 회원가입 공백 | BE 가 `AuthServiceImpl.signup()` 에서 EGG UserCharacter 자동 생성 | FE 가 현재 온보딩 강제 안 함 확인. API 호환성 유지 (`receiveEgg()` 가 멱등) |

---

## 3. 스키마 변경 (ddl-auto: update 자동 처리 + 데이터 SQL 수동 실행)

### 3.1 `characters` 테이블

```sql
ALTER TABLE characters
  ADD COLUMN required_exp INT NULL AFTER stage;

-- 기존 row 데이터 채우기 (운영·dev 모두 실행 필요)
UPDATE characters SET required_exp = 0   WHERE stage = 'EGG';
UPDATE characters SET required_exp = 100 WHERE stage = 'BABY';
UPDATE characters SET required_exp = 200 WHERE stage = 'TEEN';
UPDATE characters SET required_exp = 300 WHERE stage = 'ADULT';
```

- **NOT NULL 은 이번 PR 에서 적용 안 함** — 모든 row 에 값이 찼는지 안전 확인 후 다음 릴리즈에서 `MODIFY COLUMN required_exp INT NOT NULL`
- 엔티티 어노테이션은 `nullable = true` 로 두고 서비스 코드에서 null 가드

### 3.2 `user_character` 테이블

```sql
ALTER TABLE user_character
  ADD COLUMN current_exp INT NOT NULL DEFAULT 0 AFTER growth_percent;

-- growth_percent 는 같은 PR 에서 DROP
ALTER TABLE user_character
  DROP COLUMN growth_percent;
```

- 기존 `growth_percent` 값은 거의 0 이므로 이관 불필요 (진화 시 0 리셋 로직상)
- FE 가 `growthPercent` 필드 미사용 확인됨 → 동시에 drop 가능

### 3.3 `todos` 테이블

```sql
ALTER TABLE todos
  ADD COLUMN exp_granted BOOLEAN NOT NULL DEFAULT FALSE AFTER is_deleted;
```

- 기존 row 는 `FALSE` 로 세팅됨. 과거 완료된 Todo 를 다시 `DONE` 전이시키면 최초 지급처럼 처리됨 — 신규 시스템 기준 적용 정책으로 수용

### 3.4 ddl-auto 와 데이터 SQL 조합 방식

현재 프로젝트는 Flyway/Liquibase 미사용, `ddl-auto: update` 로 컬럼 추가는 자동. 하지만:
- **컬럼 삭제 (`DROP COLUMN growth_percent`) 는 ddl-auto 가 자동으로 하지 않음** → 수동 SQL 필요
- **데이터 UPDATE (`required_exp` 값 채우기) 도 수동 SQL 필요**

→ **처리 방법**: `be/docs/ops/migrations/2026-04-todo-exp-system.sql` 에 마이그레이션 SQL 파일을 생성하고, 배포 전 수동 실행 절차를 docs 에 기록. 운영 DB 와 dev DB 모두 이 SQL 을 실행해야 한다는 걸 `docs/ops/run-local.md` 또는 별도 마이그레이션 섹션에 추가.

---

## 4. 엔티티 변경

### 4.1 `Character.java` (수정)

**파일**: `be/src/main/java/com/doitdo/domain/tamagotchi/entity/Character.java`

```diff
+ import jakarta.persistence.*;

  public class Character extends BaseTimeEntity {

      public enum Stage { EGG, BABY, TEEN, ADULT }

      @Id ...
      @Column(name = "character_id")
      private Long characterId;

      @Column(nullable = false, length = 20)
      private String species;

      @Enumerated(EnumType.STRING)
      @Column(nullable = false, length = 10)
      private Stage stage;

+     @Column(name = "required_exp", nullable = true)
+     private Integer requiredExp;

      @Column(name = "thumbnail_url", nullable = false, length = 500)
      private String thumbnailUrl;
  }
```

- `nullable = true` 유지 — 데이터 마이그레이션 안전성 우선. 다음 릴리즈에서 NOT NULL 전환.

### 4.2 `UserCharacter.java` (수정)

**파일**: `be/src/main/java/com/doitdo/domain/tamagotchi/entity/UserCharacter.java`

```diff
  public class UserCharacter extends BaseTimeEntity {
      ...
      @Column(length = 50)
      private String name;

-     @Column(name = "growth_percent", nullable = false)
-     private Integer growthPercent;
+     @Column(name = "current_exp", nullable = false)
+     private Integer currentExp;

      @Column(name = "is_active", nullable = false)
      private Boolean isActive;
      ...

      public void equipItem(Long userItemId) { ... }
      public void unequipItem() { ... }
      public void deactivate() { ... }
      public void setCharacterId(Long characterId) { ... }

-     public void setGrowthPercent(Integer growthPercent) {
-         this.growthPercent = growthPercent;
-     }
+     /** 진화/부화/farewell 시 exp 리셋. */
+     public void resetExp() {
+         this.currentExp = 0;
+     }
+
+     /**
+      * 경험치 가산. 현재 단계 상한에서 cap.
+      * @param delta 가산할 양 (≥0)
+      * @param cap 현재 단계의 requiredExp. null 이면 no-op.
+      */
+     public void gainExp(int delta, Integer cap) {
+         if (cap == null || delta <= 0) return;
+         int next = this.currentExp + delta;
+         this.currentExp = Math.min(cap, next);
+     }

      public void setName(String name) { ... }
  }
```

- `setGrowthPercent` 완전 제거. 호출처는 모두 `resetExp()` 로 교체.
- `gainExp(delta, cap)` 내부에서 null 가드 (`requiredExp == null` 인 엣지케이스).

### 4.3 `Todo.java` (수정)

**파일**: `be/src/main/java/com/doitdo/domain/todo/entity/Todo.java`

```diff
      @Column(name = "is_deleted", nullable = false)
      private Boolean isDeleted;

+     /**
+      * DONE 전이 시 Tamagotchi 경험치가 이미 지급됐는지 여부.
+      * 생애주기 동안 최초 1회만 true 로 세팅되어, 같은 Todo 재완료 시 중복 지급 차단.
+      */
+     @Column(name = "exp_granted", nullable = false)
+     private Boolean expGranted;

      public void softDelete() { ... }
      public void changeStatus(TodoStatus status) { ... }
      ...

+     /** 경험치 지급 완료 마킹. 멱등 (이미 true 면 no-op). */
+     public void markExpGranted() {
+         this.expGranted = true;
+     }

      public static Todo create(
              Long userId, ...) {
          return Todo.builder()
                  ...
                  .isDeleted(false)
+                 .expGranted(false)
                  .build();
      }

      public static Todo createRecurringInstance(Todo master, LocalDate occurrenceDate) {
          return Todo.builder()
                  ...
                  .isDeleted(false)
+                 .expGranted(false)
                  .build();
      }
  }
```

- 정적 팩토리 `create()`, `createRecurringInstance()` 둘 다 `expGranted(false)` 초기화 추가.

---

## 5. 이벤트 시스템 신설

### 5.1 `TodoCompletedEvent` (신규)

**파일 (신규)**: `be/src/main/java/com/doitdo/domain/todo/event/TodoCompletedEvent.java`

```java
package com.doitdo.domain.todo.event;

/**
 * TODO 가 DONE 으로 전이되었을 때 발행되는 도메인 이벤트.
 * 수신자: Tamagotchi 도메인 (exp 지급), 향후 추가 가능 (알림/통계 등).
 *
 * <p>발행 시점: {@code TodoServiceImpl.changeStatus()} 내부, DONE 전이 확정 시.
 * 수신자는 {@code AFTER_COMMIT} 단계에서 실행되므로 Todo 저장이 커밋된 뒤 동작한다.
 */
public record TodoCompletedEvent(
        Long userId,
        Long todoId
) {}
```

### 5.2 `ExpCalculator` (신규 컴포넌트)

**파일 (신규)**: `be/src/main/java/com/doitdo/domain/tamagotchi/application/ExpCalculator.java`

```java
package com.doitdo.domain.tamagotchi.application;

import java.util.Random;
import org.springframework.stereotype.Component;

/**
 * TODO 완료 시 지급 exp 양을 결정하는 컴포넌트.
 * 단순하지만 별도 클래스로 분리해 테스트에서 Random 주입 가능하게 한다.
 */
@Component
public class ExpCalculator {

    private final Random random = new Random();

    /**
     * TODO 1건 완료당 지급 exp (3~7 inclusive).
     * 현재는 단계별 차등 없음 — 단계별 차등은 Character.requiredExp 값으로만 조정.
     */
    public int rollTodoDoneExp() {
        return 3 + random.nextInt(5); // 3, 4, 5, 6, 7
    }
}
```

### 5.3 `TodoCompletionExpListener` (신규)

**파일 (신규)**: `be/src/main/java/com/doitdo/domain/tamagotchi/application/listener/TodoCompletionExpListener.java`

```java
package com.doitdo.domain.tamagotchi.application.listener;

import com.doitdo.domain.tamagotchi.application.ExpCalculator;
import com.doitdo.domain.tamagotchi.entity.Character;
import com.doitdo.domain.tamagotchi.entity.UserCharacter;
import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.repository.TodoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * TODO DONE 전이 이벤트를 구독해 UserCharacter 에 exp 를 가산하는 리스너.
 *
 * <p>설계 포인트:
 * <ul>
 *   <li>{@code AFTER_COMMIT}: Todo 저장이 커밋된 뒤에만 발동 → Todo 가 롤백되면 exp 도 지급 안 됨</li>
 *   <li>{@code REQUIRES_NEW}: exp 가산·마킹을 별도 TX 로 격리 → exp 로직이 실패해도 Todo 상태에 영향 없음</li>
 *   <li>멱등성: {@link Todo#getExpGranted()} 체크로 같은 Todo 중복 지급 차단</li>
 *   <li>활성 UC 없음: 회원가입 직후 등 공백 구간에선 조용히 skip (경험치 누락). BE 가 signup 에서 자동 EGG 생성하므로 실제로는 거의 발생 안 함.</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TodoCompletionExpListener {

    private final TodoRepository todoRepository;
    private final UserCharacterRepository userCharacterRepository;
    private final CharacterRepository characterRepository;
    private final ExpCalculator expCalculator;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void onTodoCompleted(TodoCompletedEvent event) {
        Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(event.todoId())
                .orElse(null);
        if (todo == null) {
            log.debug("[exp] todo not found; skipped todoId={}", event.todoId());
            return;
        }
        if (Boolean.TRUE.equals(todo.getExpGranted())) {
            log.debug("[exp] already granted; skipped todoId={}", event.todoId());
            return;
        }

        UserCharacter uc = userCharacterRepository
                .findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(event.userId())
                .orElse(null);
        if (uc == null) {
            log.debug("[exp] no active UC; skipped user={}", event.userId());
            return;
        }

        Character character = characterRepository.findById(uc.getCharacterId())
                .orElse(null);
        if (character == null) {
            log.warn("[exp] character row missing for UC {}", uc.getUserCharacterId());
            return;
        }
        Integer requiredExp = character.getRequiredExp();
        if (requiredExp == null || requiredExp <= 0) {
            // EGG (requiredExp=0) 또는 마이그레이션 미완료 row → exp 누적 불가. 마킹만.
            todo.markExpGranted();
            return;
        }

        int delta = expCalculator.rollTodoDoneExp();
        uc.gainExp(delta, requiredExp);
        todo.markExpGranted();
        log.debug("[exp] granted delta={} user={} todo={} currentExp={}",
                delta, event.userId(), event.todoId(), uc.getCurrentExp());
    }
}
```

- **패키지 위치 근거**: 리스너는 "Tamagotchi 도메인이 Todo 이벤트를 구독" 하는 구조. 리스너는 Tamagotchi 쪽에 두는 게 의존 방향과 일관 (Tamagotchi → Todo event 는 OK, Todo → Tamagotchi 는 피함).
- 트랜잭션 개시 시점에 `@TransactionalEventListener(AFTER_COMMIT)` + `@Transactional(REQUIRES_NEW)` 콤보 → Todo TX 커밋 후 리스너 TX 시작 → 내부 Todo/UC 변경이 새 TX 에서 커밋됨.
- EGG 단계 (`requiredExp == 0`) 에선 exp 가산은 no-op 하지만 `expGranted` 는 마킹 → 부화 후 같은 Todo 재지급 방지.

---

## 6. 서비스 로직 변경

### 6.1 `AuthServiceImpl.signup()` — EGG UserCharacter 자동 생성

**파일**: `be/src/main/java/com/doitdo/domain/auth/application/impl/AuthServiceImpl.java`

```diff
  import com.doitdo.domain.setting.repository.UserSettingRepository;
+ import com.doitdo.domain.tamagotchi.entity.Character;
+ import com.doitdo.domain.tamagotchi.entity.UserCharacter;
+ import com.doitdo.domain.tamagotchi.repository.CharacterRepository;
+ import com.doitdo.domain.tamagotchi.repository.UserCharacterRepository;
  import com.doitdo.domain.todo.application.DefaultCategoryRegistrar;
  ...

  public class AuthServiceImpl implements AuthService {
      ...
      private final DefaultCategoryRegistrar defaultCategoryRegistrar;
+     private final CharacterRepository characterRepository;
+     private final UserCharacterRepository userCharacterRepository;
      ...

      @Override
      @Transactional
      public SignupResp signup(SignupReq req) {
          if (userRepository.existsByEmail(req.email())) { ... }
          if (userRepository.existsByUsername(req.username())) { ... }

          String encodedPassword = passwordEncoder.encode(req.password());
          User user = userRepository.save(User.create(req.email(), encodedPassword, req.username()));

          userWalletRepository.save(UserWallet.create(user.getUserId()));
          userSettingRepository.save(UserSetting.create(user.getUserId()));
          defaultCategoryRegistrar.registerFor(user.getUserId());

+         // 회원가입 직후부터 exp 시스템 대상이 되도록 EGG UserCharacter 자동 생성.
+         // 기존 /api/characters/me/egg (receiveEgg) 는 이미 멱등이라 호환성 영향 없음.
+         Character eggCharacter = characterRepository
+             .findFirstByStageOrderByCharacterIdAsc(Character.Stage.EGG)
+             .orElseThrow(() -> new CustomException(UserErrorCode.U00_999)); // 또는 적절한 에러 코드 (아래 노트 참고)
+         userCharacterRepository.save(UserCharacter.builder()
+             .userId(user.getUserId())
+             .characterId(eggCharacter.getCharacterId())
+             .name("뚜잇이")
+             .currentExp(0)
+             .isActive(true)
+             .isDeleted(false)
+             .build());

          return new SignupResp(user.getUserId(), user.getEmail(), user.getUsername());
      }
```

**노트 — EGG Character row 누락 시 에러 코드**:
- 마이그레이션이 제대로 끝난 dev/prod 에선 EGG Character row 항상 존재해야 함 → 이 예외는 운영 버그 상황
- `UserErrorCode` 에 `U00_005` 같은 새 코드 추가 (예: "회원가입 초기화 실패 — 기본 캐릭터 데이터 누락") 또는 그냥 `RuntimeException` + 글로벌 500 핸들러
- **결정**: `UserErrorCode` 에 새 코드 추가 — 이유: 마이그레이션 누락 시 운영 가시성 확보
- 코드 제안: `U00_005 ("U00-005", HttpStatus.INTERNAL_SERVER_ERROR, "회원가입 초기화 실패 — 관리자에게 문의해주세요")`

### 6.2 `TodoServiceImpl.changeStatus()` — 이벤트 발행

**파일**: `be/src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java`

```diff
+ import com.doitdo.domain.todo.event.TodoCompletedEvent;
+ import org.springframework.context.ApplicationEventPublisher;

  @Service
  @RequiredArgsConstructor
  public class TodoServiceImpl implements TodoService {

      private final TodoRepository todoRepository;
      private final CategoryRepository categoryRepository;
      private final SnoozeHistoryRepository snoozeHistoryRepository;
      private final RecurrenceService recurrenceService;
+     private final ApplicationEventPublisher eventPublisher;

      ...

      @Override
      @Transactional
      public TodoDetailResp changeStatus(Long userId, Long todoId, TodoStatusChangeReq req) {
          Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
                  .orElseThrow(() -> new CustomException(TodoErrorCode.T03_001));

          if (!todo.getUserId().equals(userId)) {
              throw new CustomException(TodoErrorCode.T03_003);
          }

          if (todo.getType() == TodoType.RECURRING) {
              throw new CustomException(TodoErrorCode.T03_004);
          }

+         TodoStatus beforeStatus = todo.getStatus();
          todo.changeStatus(req.status());

+         // DONE 전이 시 Tamagotchi exp 가산 이벤트 발행.
+         // 실제 지급은 리스너가 AFTER_COMMIT + REQUIRES_NEW 로 처리 (멱등성은 Todo.expGranted 로 보장).
+         // - beforeStatus != DONE && after == DONE 일 때만 발행 → 상태 토글 시 중복 이벤트 방지
+         // - 가산 실패해도 Todo DONE 은 커밋 유지 (사용자 UX 우선)
+         if (beforeStatus != TodoStatus.DONE && req.status() == TodoStatus.DONE) {
+             eventPublisher.publishEvent(new TodoCompletedEvent(userId, todo.getTodoId()));
+         }

          String categoryName = null;
          if (todo.getCategoryId() != null) {
              categoryName = categoryRepository.findById(todo.getCategoryId())
                      .map(Category::getCategoryName)
                      .orElse(null);
          }

-         // TODO: DONE 상태 변경 시 Tamagotchi 도메인 경험치 연동 필요 — Tamagotchi 이벤트 발행 추가 예정
-
          int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
          return TodoDetailResp.from(todo, categoryName, count);
      }
```

- 기존 주석 제거.
- `ApplicationEventPublisher` 생성자 주입은 Spring Boot 의 표준.
- `beforeStatus` 캡처를 `changeStatus()` 호출 전으로 배치 — 엔티티 메서드가 in-place 변경이므로.

### 6.3 `TamagotchiServiceImpl.evolve()` — 게이팅 + cap + resetExp

**파일**: `be/src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java`

```diff
      @Override
      @Transactional
      public EvolutionResp evolve(Long userId) {
          UserCharacter userCharacter = userCharacterRepository
              .findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)
              .orElseThrow(() -> new CustomException(TamagotchiErrorCode.M05_002));

          com.doitdo.domain.tamagotchi.entity.Character currentCharacter = characterRepository
              .findById(userCharacter.getCharacterId())
              .orElseThrow(() -> new CustomException(TamagotchiErrorCode.M05_002));

+         // exp 게이팅. 현재 단계의 requiredExp 를 채워야만 진화 가능.
+         Integer requiredExp = currentCharacter.getRequiredExp();
+         if (requiredExp == null) {
+             // 데이터 마이그레이션 미완료. 운영 알람 대상.
+             throw new CustomException(TamagotchiErrorCode.M05_005);
+         }
+         if (userCharacter.getCurrentExp() < requiredExp) {
+             throw new CustomException(TamagotchiErrorCode.M05_006);
+         }

          com.doitdo.domain.tamagotchi.entity.Character.Stage beforeStage = currentCharacter.getStage();
          com.doitdo.domain.tamagotchi.entity.Character.Stage afterStage = switch (beforeStage) {
              case BABY -> com.doitdo.domain.tamagotchi.entity.Character.Stage.TEEN;
              case TEEN -> com.doitdo.domain.tamagotchi.entity.Character.Stage.ADULT;
              default -> throw new CustomException(TamagotchiErrorCode.M05_003);
          };

          com.doitdo.domain.tamagotchi.entity.Character nextCharacter = characterRepository
              .findFirstBySpeciesAndStageOrderByCharacterIdAsc(currentCharacter.getSpecies(), afterStage)
              .orElseThrow(() -> new CustomException(TamagotchiErrorCode.M05_005));

          userCharacter.setCharacterId(nextCharacter.getCharacterId());
-         userCharacter.setGrowthPercent(0);
+         userCharacter.resetExp();

          return new EvolutionResp(
              userCharacter.getUserCharacterId(),
              beforeStage.name(),
              afterStage.name(),
-             userCharacter.getGrowthPercent(),
-             getRequiredExp(afterStage),
+             userCharacter.getCurrentExp(),       // 진화 직후 0
+             nextCharacter.getRequiredExp(),       // afterStage 의 requiredExp (DB 에서 조회한 값)
              buildAnimationUrl(beforeStage, afterStage),
              nextCharacter.getThumbnailUrl(),
              Instant.now().toString()
          );
      }

-     private int getRequiredExp(com.doitdo.domain.tamagotchi.entity.Character.Stage stage) {
-         return switch (stage) {
-             case TEEN -> 100;
-             case ADULT -> 200;
-             default -> 0;
-         };
-     }
```

- `getRequiredExp()` 헬퍼 완전 삭제.
- `nextCharacter.getRequiredExp()` 는 afterStage 의 Character row 에서 바로 조회.

### 6.4 `TamagotchiServiceImpl.hatch()` — setGrowthPercent 제거

**파일**: 동일

hatch 로직 (line 139~175 부근):

```diff
          // babyCharacter 찾은 후
          userCharacter.setCharacterId(babyCharacter.getCharacterId());
-         userCharacter.setGrowthPercent(0);
+         userCharacter.resetExp(); // EGG → BABY 시 exp 리셋 (EGG 에선 어차피 0이지만 명시적 호출)

          return new HatchCharacterResp(
              babyCharacter.getCharacterId(),
              babyCharacter.getStage().name(),
              userCharacter.getName(),
              babyCharacter.getThumbnailUrl()
          );
```

### 6.5 `TamagotchiServiceImpl.receiveEgg()` — builder 변경

**파일**: 동일

```diff
          UserCharacter userCharacter = UserCharacter.builder()
              .userId(userId)
              .characterId(eggCharacter.getCharacterId())
              .name("뚜잇이")
-             .growthPercent(0)
+             .currentExp(0)
              .isActive(true)
              .isDeleted(false)
              .build();
```

### 6.6 `TamagotchiServiceImpl.approveIndependence()` (farewell) — builder 변경

**파일**: 동일 (line 259~267)

```diff
          UserCharacter nextEggCharacter = UserCharacter.builder()
              .userId(userId)
              .characterId(eggCharacter.getCharacterId())
              .name(adultUserCharacter.getName())
-             .growthPercent(0)
+             .currentExp(0)
              .isActive(true)
              .isDeleted(false)
              .build();
```

- Farewell 게이팅은 추가하지 않음 (사용자 결정: 플래그만 노출, 강제 없음).
- 기존 `M00_002` / `M00_003` 체크는 그대로 유지.

### 6.7 `TamagotchiServiceImpl.toCurrentCharacterResp()` / `getCurrentCharacter()` — 파생 계산

**파일**: 동일 (line 123~137 근처)

```diff
      private CurrentCharacterResp toCurrentCharacterResp(UserCharacter userCharacter, TamagotchiErrorCode errorCode) {
          com.doitdo.domain.tamagotchi.entity.Character character = characterRepository
              .findById(userCharacter.getCharacterId())
              .orElseThrow(() -> new CustomException(errorCode));

+         Integer requiredExp = character.getRequiredExp();
+         int growthPercent = (requiredExp == null || requiredExp == 0)
+             ? 0
+             : Math.min(100, (int) Math.round(userCharacter.getCurrentExp() * 100.0 / requiredExp));
+         boolean canEvolve = (character.getStage() == Character.Stage.BABY
+                 || character.getStage() == Character.Stage.TEEN)
+             && requiredExp != null
+             && userCharacter.getCurrentExp() >= requiredExp;
+         boolean canFarewell = character.getStage() == Character.Stage.ADULT
+             && requiredExp != null
+             && userCharacter.getCurrentExp() >= requiredExp;

          return new CurrentCharacterResp(
              character.getCharacterId(),
              userCharacter.getName(),
              character.getStage().name(),
              character.getThumbnailUrl(),
-             userCharacter.getGrowthPercent(),
+             growthPercent,
+             userCharacter.getCurrentExp(),
+             requiredExp,
+             canEvolve,
+             canFarewell,
              userCharacter.getEquipedItemsId(),
              userCharacter.getUserCharacterId()
          );
      }
```

- `receiveEgg()` 의 직접 `new CurrentCharacterResp(...)` 구성도 같이 업데이트 필요 (EGG 면 `growthPercent=0, canEvolve=false, canFarewell=false`, `currentExp=0`, `requiredExp=0`).

---

## 7. DTO 변경

### 7.1 `CurrentCharacterResp.java` (수정)

**파일**: `be/src/main/java/com/doitdo/domain/tamagotchi/api/dto/resp/CurrentCharacterResp.java`

```java
package com.doitdo.domain.tamagotchi.api.dto.resp;

import io.swagger.v3.oas.annotations.media.Schema;

public record CurrentCharacterResp(
    @Schema(description = "원본 캐릭터 식별자(characters.character_id)")
    Long characterId,
    String name,
    String stage,
    String thumbnailUrl,
    @Schema(description = "현재 단계 진행률 0~100 (currentExp * 100 / requiredExp, 파생)")
    Integer growthPercent,
    @Schema(description = "현재 단계에서 누적된 경험치")
    Integer currentExp,
    @Schema(description = "현재 단계 진화에 필요한 경험치 총량")
    Integer requiredExp,
    @Schema(description = "진화 가능 여부 (BABY/TEEN 에서 currentExp >= requiredExp)")
    Boolean canEvolve,
    @Schema(description = "독립(이별) 가능 여부 (ADULT 에서 currentExp >= requiredExp)")
    Boolean canFarewell,
    Long equippedUserItemId,
    @Schema(description = "사용자가 실제로 키우는 현재 활성 다마고치 row 식별자(user_character.user_character_id). M05~M08 path 식별자로 사용")
    Long userCharacterId
) {}
```

### 7.2 `EvolutionResp.java` (변경 없음, 의미 재해석만)

**파일**: `be/src/main/java/com/doitdo/domain/tamagotchi/api/dto/resp/EvolutionResp.java`

- 필드 구성 그대로.
- `currentExp` = 진화 직후 0, `requiredExp` = afterStage 의 DB 값.

### 7.3 `HatchCharacterResp.java` (변경 없음)

- 현재 DTO 는 `characterId, stage, name, thumbnailUrl` 만 있음 → exp 필드 없어 추가 변경 불필요.
- 부화 후 상태 조회는 `getCurrentCharacter()` 를 별도로 호출한다는 전제.

### 7.4 `TodoDetailResp.java` (변경 없음)

- `expGranted` 는 내부 운영 플래그. FE 응답에 노출하지 않음.

---

## 8. 에러 코드 추가

### 8.1 `TamagotchiErrorCode.java` (수정)

**파일**: `be/src/main/java/com/doitdo/global/exception/TamagotchiErrorCode.java`

기존 M05 섹션에 `M05_006` 추가:

```diff
      // M05 - evolution
      M05_001("M05-001", HttpStatus.UNAUTHORIZED, "인증 토큰이 없거나 유효하지 않음"),
      M05_002("M05-002", HttpStatus.NOT_FOUND, "다마고치를 찾을 수 없음"),
      M05_003("M05-003", HttpStatus.UNPROCESSABLE_ENTITY, "상태가 진화 조건에 맞지 않음"),
      M05_004("M05-004", HttpStatus.INTERNAL_SERVER_ERROR, "서버 내부 오류"),
      M05_005("M05-005", HttpStatus.CONFLICT, "이미 진화했거나 추가 진화가 불가함"),
+     M05_006("M05-006", HttpStatus.CONFLICT, "아직 진화할 수 없습니다. 경험치가 더 필요합니다."),
```

- **HTTP 409 Conflict** — "현재 상태에서 이 요청 처리 불가" 의미. 400/422 보다 정확.
- 메시지 톤은 안내형 (에러 공격성 낮춤). FE 는 선제 차단(`canEvolve=false`) 을 기본으로, 이 응답은 race/bug 대응.

### 8.2 `UserErrorCode.java` (수정) — signup 초기화 실패 코드

**파일**: `be/src/main/java/com/doitdo/global/exception/UserErrorCode.java`

```diff
      // 기존 U00_001 ~ U00_004 유지
+     U00_005("U00-005", HttpStatus.INTERNAL_SERVER_ERROR, "회원가입 초기화 실패 — 관리자에게 문의해주세요"),
```

- EGG Character row 누락 같은 운영 이슈 대비. 일반적인 상황에선 발생 안 함.
- 다음 번호가 현재 `UserErrorCode` 에 무엇이 있는지는 파일 열어서 확인 후 반영 (U00_005 가 이미 있으면 U00_006 등). **Sonnet 은 해당 파일을 먼저 읽어 번호 확정 후 추가할 것.**

---

## 9. 테스트

### 9.1 기존 테스트 수정

**`TamagotchiServiceImplTest.java`**:

현재 `line 373` 에 `assertThat(resp.requiredExp()).isEqualTo(100)` 이 존재. BABY → TEEN 진화 시나리오면 afterStage 의 requiredExp 가 **TEEN=200** 이므로 기댓값을 200 으로 수정 필요. (또는 현재 테스트가 어떤 stage 전이를 다루는지에 따라 기댓값 재계산 — Sonnet 이 read 후 판단)

진화 테스트들은 **게이팅이 추가된 이후** 에도 통과하려면 setup 에서 `userCharacter.gainExp(requiredExp, requiredExp)` 로 미리 채우거나, 테스트용 fixture 에 `currentExp=requiredExp` 로 세팅해야 함.

### 9.2 신규 테스트

**`ExpCalculatorTest.java` (신규)**:
- `rollTodoDoneExp()` 를 1000회 호출 → 결과가 모두 `3 <= x <= 7` 범위 내인지 검증

**`TodoCompletionExpListenerTest.java` (신규)**:
- `@SpringBootTest` 또는 Mockito 기반 단위 테스트 (팀 컨벤션 따름)
- 시나리오:
  1. 최초 DONE 전이 → exp 지급 + `expGranted=true`
  2. 이미 `expGranted=true` → skip, currentExp 변화 없음
  3. UserCharacter 없음 → 예외 없이 skip
  4. Character.requiredExp == null → `expGranted` 만 마킹, exp 변화 없음
  5. Cap 동작: `currentExp=95`, delta=7 (cap=100) → `currentExp=100` (5만 가산)

**`TodoServiceImplTest` 또는 Spring Event 검증**:
- 조건부 발행 검증:
  1. `TODO → DONE` → `TodoCompletedEvent` 1건 발행
  2. `DONE → DONE` (req 상태가 동일) → 이벤트 0건 (변화 없음)
  3. `IN_PROGRESS → DONE` → 이벤트 1건
  4. `DONE → IN_PROGRESS` → 이벤트 0건
- Spring 의 `ApplicationEvents` 테스트 유틸 또는 Mockito `@MockBean ApplicationEventPublisher` 활용

**진화 게이팅 테스트 (`TamagotchiServiceImplTest` 확장)**:
- exp 부족 → `M05_006` 발생
- exp 충족 (`currentExp == requiredExp`) → 정상 진화 + `currentExp=0` 리셋
- NULL requiredExp → `M05_005`

**자동 EGG 생성 테스트 (`AuthServiceImplTest`, 기존 있으면 확장)**:
- signup 성공 후 `userCharacterRepository.findFirstByUserIdAndIsActiveTrueAndIsDeletedFalse(userId)` 가 EGG 단계 UC 반환하는지

### 9.3 E2E 영향

- `be/scripts/e2e/run.py` 의 Phase 5 (다마고치) / Phase 6 (TODO) 이미 존재.
- 이번 PR 범위에서 별도 step 추가는 선택 사항. 구현 후 수동으로 돌려서 회귀 없음 확인 정도로 충분.
- 신규 step 추가 시 제안: "TODO 완료 후 현재 캐릭터 재조회 → currentExp 증가 확인"

---

## 10. Docs 갱신 (CLAUDE.md 규칙 — 같은 PR 에서 필수)

### 10.1 `docs/api/error-codes.md`
- `M05_006` 추가
- `U00_005` 추가 (또는 실제 부여된 번호)

### 10.2 `docs/architecture/package-layout.md`
- `domain/todo/event/` (신규)
- `domain/tamagotchi/application/listener/` (신규)
- `domain/tamagotchi/application/ExpCalculator` (신규)
- 패키지 트리 업데이트

### 10.3 `docs/conventions/domain-events.md` (신규 파일)
프로젝트의 첫 `@TransactionalEventListener` 도입이므로 컨벤션 문서화.

내용:
- 이벤트 네이밍: `<Domain><Action>Event` 과거형 (예: `TodoCompletedEvent`)
- 이벤트 위치: 발행 도메인 하위 `event/` 패키지
- 리스너 위치: 구독 도메인 하위 `application/listener/` 패키지
- 트랜잭션 경계 표준: `@TransactionalEventListener(phase = AFTER_COMMIT)` + `@Transactional(propagation = REQUIRES_NEW)`
- 멱등성 책임: 리스너가 담당. 발행자는 상태 전이만 감지
- 이벤트 payload 는 `record` + primitive/id 만 권장 (엔티티 직접 담지 말 것)
- 이벤트 소실 리스크 인정: `AFTER_COMMIT` 이후 JVM 크래시 시점에 수 ms 창 존재 → MVP 수용, 필요 시 Outbox 패턴 도입

### 10.4 `docs/ops/migrations/2026-04-todo-exp-system.sql` (신규)
섹션 3 의 SQL 전체를 파일로 저장. 배포 전 운영 DB 에 수동 실행.

### 10.5 `docs/api/tamagotchi.md` (있으면 업데이트, 없으면 명세는 Notion SSOT)
- `/evolution` 의 M05_006 명세
- `CurrentCharacterResp` 의 `currentExp`, `requiredExp`, `canEvolve`, `canFarewell` 추가

---

## 11. 파일 변경 리스트 요약

### 신규 (10개)
- `be/src/main/java/com/doitdo/domain/todo/event/TodoCompletedEvent.java`
- `be/src/main/java/com/doitdo/domain/tamagotchi/application/ExpCalculator.java`
- `be/src/main/java/com/doitdo/domain/tamagotchi/application/listener/TodoCompletionExpListener.java`
- `be/src/test/java/com/doitdo/domain/tamagotchi/application/ExpCalculatorTest.java`
- `be/src/test/java/com/doitdo/domain/tamagotchi/application/listener/TodoCompletionExpListenerTest.java`
- `be/docs/plans/todo-exp-system.md` (← 이 문서)
- `be/docs/conventions/domain-events.md`
- `be/docs/ops/migrations/2026-04-todo-exp-system.sql`
- (선택) `be/src/test/java/com/doitdo/domain/todo/application/impl/TodoServiceEventTest.java` — 이벤트 발행 검증용
- `be/docs/api/tamagotchi.md` (없으면 신규, 있으면 수정)

### 수정 (13개)
- `be/src/main/java/com/doitdo/domain/tamagotchi/entity/Character.java`
- `be/src/main/java/com/doitdo/domain/tamagotchi/entity/UserCharacter.java`
- `be/src/main/java/com/doitdo/domain/todo/entity/Todo.java`
- `be/src/main/java/com/doitdo/domain/auth/application/impl/AuthServiceImpl.java`
- `be/src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java`
- `be/src/main/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImpl.java`
- `be/src/main/java/com/doitdo/domain/tamagotchi/api/dto/resp/CurrentCharacterResp.java`
- `be/src/main/java/com/doitdo/global/exception/TamagotchiErrorCode.java`
- `be/src/main/java/com/doitdo/global/exception/UserErrorCode.java`
- `be/src/test/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImplTest.java`
- `be/docs/api/error-codes.md`
- `be/docs/architecture/package-layout.md`
- (선택) `be/src/test/java/com/doitdo/domain/auth/...` AuthServiceImplTest (존재 여부에 따라)

---

<!-- QUESTION: 커밋 1 에서 UserCharacter.growthPercent 필드/세터를 제거하면 TamagotchiServiceImpl 소비처(receiveEgg/hatch/evolve/approveIndependence)가 컴파일 실패. growthPercent 드롭은 커밋 5(소비처 DTO 이주)와 함께 처리하는 옵션 A 로 구현함. 커밋 1 에서는 currentExp 추가만 수행하고 growthPercent 는 커밋 5 에서 제거. -->

<!-- QUESTION: 플랜 6.3 diff 에서 evolve(Long userId) 로 표시되어 있으나 실제 코드는 evolve(Long userId, Long userCharacterId) 시그니처. 컨트롤러 호환성 유지를 위해 userCharacterId 파라미터 및 검증 로직은 그대로 유지하고 exp 게이팅만 추가. -->

## 12. PR 커밋 분할 (단일 PR, 논리 단위 6커밋)

```
1. feat: add required_exp/current_exp/exp_granted columns + entity fields
   - Character.requiredExp, UserCharacter.currentExp, Todo.expGranted
   - UserCharacter.resetExp(), UserCharacter.gainExp(), Todo.markExpGranted()
   - 정적 팩토리 초기화 업데이트
   - docs/ops/migrations/2026-04-todo-exp-system.sql

2. feat: implement TodoCompletedEvent + ExpCalculator + listener with farming guard
   - TodoCompletedEvent record
   - ExpCalculator component (3~7 랜덤)
   - TodoCompletionExpListener with AFTER_COMMIT + REQUIRES_NEW

3. feat: publish TodoCompletedEvent from TodoServiceImpl on DONE transition
   - ApplicationEventPublisher 주입
   - changeStatus() 에 조건부 발행 로직
   - 기존 "TODO: Tamagotchi 이벤트 발행 추가 예정" 주석 제거

4. feat: add evolution exp gating and auto-assign EGG on signup
   - TamagotchiServiceImpl.evolve() 에 M05_006 게이팅 추가
   - getRequiredExp() 하드코딩 제거
   - hatch/farewell/receiveEgg 의 setGrowthPercent → resetExp 교체
   - AuthServiceImpl.signup() 에 EGG UserCharacter 자동 생성
   - TamagotchiErrorCode.M05_006, UserErrorCode.U00_005 추가

5. feat: expose derived growthPercent/canEvolve/canFarewell in CurrentCharacterResp
   - CurrentCharacterResp 필드 추가 (currentExp, requiredExp, canEvolve, canFarewell)
   - toCurrentCharacterResp() 파생 계산 로직
   - receiveEgg() 의 직접 DTO 생성 부분 업데이트

6. test+docs: add exp system tests + update error-codes/package-layout + domain-events convention
   - ExpCalculatorTest, TodoCompletionExpListenerTest, TamagotchiServiceImplTest 확장
   - docs/api/error-codes.md, docs/architecture/package-layout.md 업데이트
   - docs/conventions/domain-events.md 신규
```

---

## 13. 검증 체크리스트

구현 완료 후 아래 순서로 검증:

### 13.1 컴파일·테스트
- [ ] `./gradlew compileJava` — BUILD SUCCESSFUL
- [ ] `./gradlew test` — 모든 테스트 통과 (기존 테스트 + 신규)
- [ ] 테스트 커버리지 ExpCalculator / Listener / Evolution gating 포함

### 13.2 수동 검증 (로컬)
1. [ ] DB 스키마 확인: `DESCRIBE characters` / `DESCRIBE user_character` / `DESCRIBE todos` 에 새 컬럼 반영
2. [ ] `SELECT character_id, stage, required_exp FROM characters` — EGG=0, BABY=100, TEEN=200, ADULT=300
3. [ ] 신규 유저 가입 → `SELECT * FROM user_character WHERE user_id=?` 로 EGG UC 자동 생성 확인
4. [ ] TODO 10건 생성 후 DONE 전이 → `current_exp` 가 30~70 사이로 증가 + 그에 대응하는 `growth_percent` 파생값 노출
5. [ ] 같은 Todo 를 `IN_PROGRESS → DONE` 로 되돌렸다가 다시 `DONE` → `current_exp` 변화 없음
6. [ ] BABY 에서 `current_exp < 100` 인 상태로 `/evolution` 호출 → HTTP 409 + M05_006
7. [ ] BABY 에서 `current_exp == 100` 으로 `/evolution` → TEEN 전이 + `current_exp=0` 리셋
8. [ ] ADULT 에서 `current_exp == 300` → `GET /api/characters/me` 응답 `canFarewell=true`
9. [ ] `/farewell` 호출 → 새 EGG UC 자동 생성 + 기존 ADULT UC `is_active=false`

### 13.3 Swagger
- [ ] `/swagger-ui.html?group=tamagotchi` 에서 `M05_006` 노출
- [ ] `CurrentCharacterResp` 의 신규 필드들 Schema 노출

### 13.4 Notion 동기
- [ ] [T03 페이지](https://www.notion.so/TODO-3428ab5fe9a9819892c9e0e942322f94) 의 exp 연동 섹션과 실제 구현 일치

### 13.5 E2E (선택)
- [ ] `python3 scripts/e2e/run.py --local` 전 phase 녹색
- [ ] Phase 6 (TODO) 후 Phase 5 재조회로 currentExp 증가 확인

---

## 14. 엣지 케이스 / 열린 질문

| # | 케이스 | 처리 방침 |
|---|--------|-----------|
| E1 | 회원가입 시 EGG Character row 누락 | `U00_005` throw, 500 — 운영 알람 대상 |
| E2 | 리스너에서 UserCharacter 없음 | 조용히 skip, debug 로그. 회원가입 자동 EGG 로 실제 거의 발생 안 함 |
| E3 | Character.requiredExp NULL | 리스너: 마킹만, exp 가산 no-op / evolve: M05_005 |
| E4 | Cap 도달 후 추가 DONE | `gainExp` 내부에서 `Math.min` 으로 자동 캡 |
| E5 | RECURRING occurrence 완료 | 본 PR 범위 밖. `changeStatus` 에서 T03_004 차단되는 현재 경로 유지 |
| E6 | 서버 크래시로 AFTER_COMMIT 이벤트 소실 | MVP 수용. 향후 Outbox 패턴 검토 (별도 스토리) |
| E7 | 동일 유저의 동시 TODO DONE 여러 건 | Spring 이벤트는 기본 동기 처리 → 순차 적용. 실제 race 없음 |
| E8 | 탈퇴 후 이벤트 도착 | 리스너가 active UC 못 찾음 → skip |

---

## 15. 위임 지침 (Sonnet 에게 전달할 운영 규칙)

- 브랜치 먼저 생성: `git checkout -b be/feat/todo-exp-system origin/dev`
- CDP MCP 사용 금지
- 구현 중 설계상 모호점 발견 시: 자체 판단하지 말고 이 plan 파일에 `<!-- QUESTION: ... -->` 주석으로 표시 후 구현 중단, 사용자에게 escalate
- `./gradlew compileJava` 로 컴파일 검증을 커밋 분할마다 (최소 한 번 전체)
- 테스트는 `./gradlew test` 로 green 확인
- 마이그레이션 SQL 파일은 배포 전 수동 실행이 필요함을 docs 에 명시
- PR 제목: `[BE : feat] TODO 완료 연동 경험치 시스템 (exp system)` — MR 타이틀 컨벤션 준수
- 커밋 메시지 컨벤션: `feat : ` / `test : ` / `docs : ` prefix (`git log` 확인)
- **본 plan 파일은 Sonnet 이 직접 수정 금지**. Head (Claude) 가 구현 완료 후 `completed_plans/` 로 이동.
