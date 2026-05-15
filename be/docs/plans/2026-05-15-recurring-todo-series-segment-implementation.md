# Recurring TODO Series Segment Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** `scope=from` 반복 TODO 수정/삭제가 같은 반복 그룹의 기준일 이후 구간 전체에 반영되도록 변경한다.

**Architecture:** `todos.recurrence_group_id` 로 같은 반복 흐름을 묶고, 각 RECURRING row 를 날짜 구간 마스터로 취급한다. `scope=from` 은 같은 그룹에서 기준일 이후와 겹치는 마스터를 조회해 앞 구간은 자르고 이후 구간은 삭제한 뒤, 수정 요청이면 새 구간 마스터를 생성한다.

**Tech Stack:** Spring Boot 3.5.13, Java 21, JPA, MariaDB, Gradle, JUnit 5, Mockito

---

### Task 1: Entity And Migration

**Files:**
- Modify: `src/main/java/com/doitdo/domain/todo/entity/Todo.java`
- Create: `docs/ops/migrations/2026-05-15-recurring-todo-group-id.sql`

**Step 1: Write the failing test**

`src/test/java/com/doitdo/domain/todo/application/impl/TodoServiceImplTest.java` 에 RECURRING 생성 결과가 `recurrenceGroupId` 를 가지는 테스트를 추가한다.

```java
@Test
void createRecurringAssignsOwnTodoIdAsRecurrenceGroupId() {
	Todo saved = Todo.create(1L, null, null, null, "task1", null,
			TodoType.RECURRING, 1, null, LocalDate.parse("2026-05-01"),
			LocalDate.parse("2026-05-30"), Set.of(DayOfWeek.FRIDAY));

	given(todoRepository.save(any(Todo.class))).willAnswer(invocation -> {
		Todo todo = invocation.getArgument(0);
		ReflectionTestUtils.setField(todo, "todoId", 10L);
		return todo;
	});

	service.create(1L, recurringCreateReq());

	assertThat(saved.getRecurrenceGroupId()).isEqualTo(10L);
}
```

**Step 2: Run test to verify it fails**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest.createRecurringAssignsOwnTodoIdAsRecurrenceGroupId"`

Expected: FAIL because `getRecurrenceGroupId()` does not exist.

**Step 3: Write minimal implementation**

- `Todo` 에 `recurrenceGroupId` 필드와 `assignRecurrenceGroupIdIfAbsent()` 추가.
- `Todo.createRecurringInstance()` 에서 마스터의 group ID 복사.
- `TodoServiceImpl.create()` 에서 RECURRING 저장 후 group ID 초기화.
- migration 에 컬럼/인덱스/백필 SQL 추가.

**Step 4: Run test to verify it passes**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest.createRecurringAssignsOwnTodoIdAsRecurrenceGroupId"`

Expected: PASS

### Task 2: Repository Queries

**Files:**
- Modify: `src/main/java/com/doitdo/domain/todo/repository/TodoRepository.java`
- Test: `src/test/java/com/doitdo/domain/todo/application/impl/TodoServiceImplTest.java`

**Step 1: Write the failing test**

`updateRecurringFrom...` 기존 테스트를 확장해 `findRecurringMastersOverlappingFromDate()` 호출을 검증한다.

**Step 2: Run test to verify it fails**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest.updateRecurringFromCutsOverlappingGroupSegments"`

Expected: FAIL because repository method does not exist.

**Step 3: Write minimal implementation**

Repository query 추가:

- 같은 `userId`
- 같은 `recurrenceGroupId`
- `type = RECURRING`
- `isDeleted = false`
- `endDate IS NULL OR endDate >= :occurrenceDate`

정렬은 `startDate ASC, todoId ASC`.

**Step 4: Run test**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest.updateRecurringFromCutsOverlappingGroupSegments"`

Expected: repository 컴파일 통과 후 서비스 로직 미구현으로 FAIL.

### Task 3: Update Scope From Segment Logic

**Files:**
- Modify: `src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java`
- Test: `src/test/java/com/doitdo/domain/todo/application/impl/TodoServiceImplTest.java`

**Step 1: Write the failing test**

시나리오:

- `task1 5/1~5/9`
- `task2 5/10~5/19`
- `task3 5/20~5/30`
- `5/15 이후 task4` 수정

기대:

- `task2.endDate == 5/14`
- `task3.isDeleted == true`
- 새 마스터는 `5/15~5/30`, 같은 `recurrenceGroupId`

**Step 2: Run test to verify it fails**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest.updateRecurringFromCutsOverlappingGroupSegments"`

Expected: FAIL because 현재 코드는 요청 마스터 하나만 자른다.

**Step 3: Write minimal implementation**

- `resolveRecurrenceGroupId(master)` 헬퍼 추가.
- `findRecurringMastersOverlappingFromDate()` 결과 중:
  - `startDate < occurrenceDate` 이면 `endDate = occurrenceDate.minusDays(1)`
  - `startDate >= occurrenceDate` 이면 soft delete
- 새 마스터의 `endDate` 는 요청값이 없으면 영향받은 마스터들의 가장 늦은 종료일 사용.
- 새 마스터의 `recurrenceGroupId` 는 기존 group ID 사용.

**Step 4: Run test**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest.updateRecurringFromCutsOverlappingGroupSegments"`

Expected: PASS

### Task 4: Delete Scope From Segment Logic

**Files:**
- Modify: `src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java`
- Test: `src/test/java/com/doitdo/domain/todo/application/impl/TodoServiceImplTest.java`

**Step 1: Write the failing test**

같은 3구간 상태에서 `5/15 이후 삭제` 시:

- `task1` 유지
- `task2.endDate == 5/14`
- `task3.isDeleted == true`

**Step 2: Run test to verify it fails**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest.deleteRecurringFromCutsOverlappingGroupSegments"`

Expected: FAIL because 현재 코드는 요청 마스터 하나만 처리한다.

**Step 3: Write minimal implementation**

`delete(scope=from)` 에서 Task 3 의 구간 정리 로직을 재사용하고 새 마스터 생성만 생략한다.

**Step 4: Run test**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest.deleteRecurringFromCutsOverlappingGroupSegments"`

Expected: PASS

### Task 5: Future Materialized Instances

**Files:**
- Modify: `src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java`
- Modify: `src/main/java/com/doitdo/domain/todo/repository/TodoRepository.java`
- Test: `src/test/java/com/doitdo/domain/todo/application/impl/TodoServiceImplTest.java`

**Step 1: Write the failing test**

기준일 이후에 이미 생성된 NORMAL 인스턴스가 같은 그룹에 있으면 soft delete 되는지 검증한다.

**Step 2: Run test to verify it fails**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest.updateRecurringFromDeletesFutureMaterializedInstancesAcrossGroup"`

Expected: FAIL because 현재 코드는 요청 마스터의 인스턴스만 삭제한다.

**Step 3: Write minimal implementation**

같은 그룹의 영향받은 마스터 ID 목록을 기준으로 `startDate >= occurrenceDate` 인 NORMAL 인스턴스를 조회해 soft delete 한다.

**Step 4: Run test**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest.updateRecurringFromDeletesFutureMaterializedInstancesAcrossGroup"`

Expected: PASS

### Task 6: Regression Run

**Files:**
- Verify only

**Step 1: Run focused test class**

Run: `.\gradlew.bat test --tests "com.doitdo.domain.todo.application.impl.TodoServiceImplTest"`

Expected: PASS

**Step 2: Run recurrence tests**

Run: `.\gradlew.bat test --tests "*Recurrence*"`

Expected: PASS

**Step 3: Check git diff**

Run: `git diff -- src/main/java/com/doitdo/domain/todo src/test/java/com/doitdo/domain/todo docs/ops/migrations docs/plans`

Expected: only recurrence group/segment changes and docs.
