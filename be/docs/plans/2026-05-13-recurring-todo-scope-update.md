# 반복 TODO 선택 날짜 수정/삭제 설계 및 구현 계획

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 캘린더에서 선택한 반복 TODO 발생일(`occurrenceDate`) 기준으로 "하루만" 또는 "해당 날짜 포함 이후 전부" 삭제/수정을 지원한다.

**Architecture:** 새 테이블은 만들지 않는다. 기존 `todos.master_todo_id`와 `todos.start_date`를 사용해 반복 마스터와 날짜별 NORMAL 인스턴스를 연결한다. "하루만 삭제"는 soft-deleted NORMAL 인스턴스를 가상 occurrence 생성 금지 마커로 재사용한다.

**Tech Stack:** Spring Boot 3.5.13, Java 21, JPA, MariaDB, Redis cache, springdoc-openapi

---

## 1. 배경

현재 반복 TODO는 다음 구조다.

| 구분 | 저장 형태 |
|---|---|
| 반복 마스터 | `type=RECURRING`, `master_todo_id=NULL` |
| 날짜별 실체 인스턴스 | `type=NORMAL`, `master_todo_id=<마스터 todo_id>`, `start_date=<발생일>` |
| 가상 인스턴스 | DB row 없음. `GET /api/todos/calendar` 조회 중 반복 규칙으로 합성 |

기존에는 반복 마스터 전체 삭제(`scope=all`)와 상태 변경/미루기 시 on-demand 실체화만 지원했다. 이번 변경은 사용자가 캘린더에서 선택한 특정 `occurrenceDate`를 기준으로 삭제/수정 범위를 선택할 수 있게 한다.

## 2. 최종 결정

`recurring_exceptions` 같은 별도 테이블은 추가하지 않는다.

이유:

- 현재 요구사항에서 별도 테이블이 실제로 필요한 케이스는 "아직 실체화되지 않은 하루만 삭제"뿐이다.
- `todos.master_todo_id + start_date + is_deleted=true` 조합으로 같은 의미를 표현할 수 있다.
- 마이그레이션, 엔티티, 레포지토리, 캘린더 조인 범위를 늘리지 않고 기존 모델을 유지할 수 있다.

핵심 규칙:

```text
삭제된 NORMAL 파생 인스턴스는 화면에 응답하지 않는다.
하지만 같은 master_todo_id + start_date의 RECURRING 가상 인스턴스 생성을 막는 마커로 사용한다.
```

## 3. API 변경

새 URL은 추가하지 않는다. 기존 삭제/수정 API의 query parameter를 확장한다.

### 삭제

```http
DELETE /api/todos/{todoId}?scope=only&occurrenceDate=2026-05-13
DELETE /api/todos/{todoId}?scope=from&occurrenceDate=2026-05-13
DELETE /api/todos/{todoId}?scope=all
```

| 파라미터 | 타입 | 필수 | 의미 |
|---|---|---|---|
| `scope` | String | 아니오 | `only`, `from`, `all`, 기존 default 단건 |
| `occurrenceDate` | LocalDate | 조건부 | `todoId`가 RECURRING 마스터이고 `scope=only/from`이면 필수 |

### 수정

```http
PATCH /api/todos/{todoId}?scope=only&occurrenceDate=2026-05-13
PATCH /api/todos/{todoId}?scope=from&occurrenceDate=2026-05-13
```

| 파라미터 | 타입 | 필수 | 의미 |
|---|---|---|---|
| `scope` | String | 아니오 | `only`, `from`, 기존 default 단건 |
| `occurrenceDate` | LocalDate | 조건부 | `todoId`가 RECURRING 마스터이고 `scope=only/from`이면 필수 |
| body | `TodoUpdateReq` | 예 | 기존 수정 body 재사용 |

## 4. 동작 정책

### 4.1 하루만 삭제 (`scope=only`)

대상은 RECURRING 마스터와 선택한 `occurrenceDate`다.

처리:

1. `occurrenceDate`가 반복 마스터 규칙에 맞는 날짜인지 검증한다.
2. 해당 날짜의 NORMAL 인스턴스를 찾거나 생성한다.
3. 해당 NORMAL 인스턴스를 `isDeleted=true`로 soft delete 한다.
4. 캘린더 조회 시 이 삭제 row는 응답하지 않는다.
5. 대신 같은 `master_todo_id + start_date`의 가상 occurrence 생성을 차단한다.

저장 예:

```text
todo_id=101
type=NORMAL
master_todo_id=7
start_date=2026-05-13
is_deleted=true
```

### 4.2 오늘 포함 이후 전부 삭제 (`scope=from`)

대상은 RECURRING 마스터와 선택한 `occurrenceDate` 이후다.

처리:

1. `occurrenceDate`가 반복 마스터 규칙에 맞는 날짜인지 검증한다.
2. 기존 마스터의 `endDate`를 `occurrenceDate.minusDays(1)`로 변경한다.
3. `master_todo_id=<마스터 id>`이고 `start_date >= occurrenceDate`인 NORMAL 인스턴스를 soft delete 한다.
4. 새 마스터는 만들지 않는다.

결과:

```text
기존 마스터: startDate=2026-05-01, endDate=2026-05-12
2026-05-13 이후 가상 occurrence 없음
```

### 4.3 하루만 수정 (`scope=only`)

대상은 선택한 날짜 하나다.

처리:

1. `occurrenceDate`가 반복 마스터 규칙에 맞는 날짜인지 검증한다.
2. 해당 날짜의 NORMAL 인스턴스를 찾거나 생성한다.
3. `TodoUpdateReq`를 해당 NORMAL 인스턴스에만 적용한다.
4. 반복 마스터와 다른 날짜 occurrence는 변경하지 않는다.

결과:

```text
2026-05-13만 수정된 NORMAL row 응답
2026-05-14 이후는 기존 RECURRING 마스터 기준 가상/실체 응답
```

### 4.4 오늘 포함 이후 전부 수정 (`scope=from`)

대상은 선택한 날짜부터의 반복 규칙 전체다.

처리:

1. `occurrenceDate`가 반복 마스터 규칙에 맞는 날짜인지 검증한다.
2. 기존 마스터의 `endDate`를 `occurrenceDate.minusDays(1)`로 변경한다.
3. `master_todo_id=<기존 마스터 id>`이고 `start_date >= occurrenceDate`인 기존 NORMAL 인스턴스를 soft delete 한다.
4. 수정 body를 반영한 새 RECURRING 마스터를 생성한다.
5. 새 마스터의 `startDate`는 반드시 `occurrenceDate`다.

결과:

```text
기존 마스터: 2026-05-01 ~ 2026-05-12
새 마스터: 2026-05-13 ~ 수정된 endDate
```

응답은 새 RECURRING 마스터의 `TodoDetailResp`를 반환한다. FE는 이 응답의 `todoId`를 새 마스터 id로 반영해야 한다.

## 5. 캘린더 조회 변경

현재 캘린더 합성은 "실체 인스턴스가 있는 날짜는 가상 인스턴스를 만들지 않는다"는 정책을 가진다.

이번 변경 후 기준을 분리한다.

| 용도 | 포함 조건 |
|---|---|
| 응답할 실체 TODO | `isDeleted=false` |
| 가상 생성 차단 마커 | `isDeleted`와 무관하게 `master_todo_id`, `start_date`가 일치하는 파생 인스턴스 |

즉 삭제된 파생 인스턴스는 응답에는 포함하지 않지만, 가상 인스턴스 생성 차단에는 포함한다.

의사 코드:

```java
List<Todo> actualItems = findCalendarItems(userId, from, to, isDeletedFalse);
List<Todo> recurringMarkers = findRecurringInstanceMarkers(userId, masterIds, from, to);

Set<OccurrenceKey> blocked = recurringMarkers.stream()
    .map(todo -> new OccurrenceKey(todo.getMasterTodoId(), todo.getStartDate()))
    .collect(toSet());

for (Todo master : recurringMasters) {
    for (LocalDate occurrenceDate : generate(master, from, to)) {
        if (blocked.contains(new OccurrenceKey(master.getTodoId(), occurrenceDate))) {
            continue;
        }
        addVirtualItem(master, occurrenceDate);
    }
}
```

## 6. 파일별 구현 계획

### Task 1: Request scope 모델 정리

**Files:**

- Modify: `src/main/java/com/doitdo/domain/todo/api/controller/TodoController.java`
- Modify: `src/main/java/com/doitdo/domain/todo/application/TodoService.java`
- Modify: `src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java`

**작업:**

1. `DELETE /api/todos/{todoId}`에 `@RequestParam(required=false) LocalDate occurrenceDate` 추가.
2. `PATCH /api/todos/{todoId}`에 `@RequestParam(required=false) String scope`, `@RequestParam(required=false) LocalDate occurrenceDate` 추가.
3. 서비스 시그니처를 다음 형태로 확장.

```java
void delete(Long userId, Long todoId, String scope, LocalDate occurrenceDate);

TodoDetailResp update(Long userId, Long todoId, TodoUpdateReq req, String scope, LocalDate occurrenceDate);
```

### Task 2: 반복 occurrence 검증 유틸 정리

**Files:**

- Modify: `src/main/java/com/doitdo/domain/todo/application/impl/RecurrenceServiceImpl.java`
- Modify: `src/main/java/com/doitdo/domain/todo/application/RecurrenceService.java`

**작업:**

1. 기존 `materializeRecurringOccurrence`의 발생일 검증 로직을 재사용한다.
2. `scope=only/from`에서 `occurrenceDate`가 null이면 TODO 도메인 에러를 던진다.
3. `occurrenceDate`가 마스터의 요일/기간 규칙에 맞지 않으면 기존 반복 occurrence 에러와 같은 계열로 처리한다.

### Task 3: 하루만 삭제 구현

**Files:**

- Modify: `src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java`

**작업:**

1. `todo.type == RECURRING && scope=only` 분기 추가.
2. `recurrenceService.materializeRecurringOccurrence(userId, todo, occurrenceDate)` 호출.
3. 반환된 NORMAL 인스턴스를 `softDelete()`.
4. 사용자 TODO 목록 cache evict.
5. 마스터 item cache와 인스턴스 item cache evict.

### Task 4: 이후 전부 삭제 구현

**Files:**

- Modify: `src/main/java/com/doitdo/domain/todo/entity/Todo.java`
- Modify: `src/main/java/com/doitdo/domain/todo/repository/TodoRepository.java`
- Modify: `src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java`

**작업:**

1. `Todo`에 `changeEndDate(LocalDate endDate)` 같은 최소 메서드 추가.
2. `TodoRepository`에 미래 파생 인스턴스 조회 추가.

```java
List<Todo> findAllByUserIdAndMasterTodoIdAndStartDateGreaterThanEqual(
        Long userId,
        Long masterTodoId,
        LocalDate startDate);
```

3. `scope=from` 삭제 시 마스터 `endDate = occurrenceDate.minusDays(1)`.
4. 미래 파생 인스턴스 soft delete.

### Task 5: 하루만 수정 구현

**Files:**

- Modify: `src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java`

**작업:**

1. `todo.type == RECURRING && scope=only` 분기 추가.
2. 해당 occurrence를 NORMAL 인스턴스로 실체화.
3. 기존 update 로직을 인스턴스 대상으로 적용한다.
4. 응답은 수정된 NORMAL 인스턴스의 `TodoDetailResp`.

주의:

- 이 경우 `req.type`을 RECURRING으로 바꾸는 요청은 허용하지 않는 편이 안전하다.
- 하루만 수정된 인스턴스는 `type=NORMAL`로 남는다.

### Task 6: 이후 전부 수정 구현

**Files:**

- Modify: `src/main/java/com/doitdo/domain/todo/application/impl/TodoServiceImpl.java`
- Modify: `src/main/java/com/doitdo/domain/todo/entity/Todo.java`
- Modify: `src/main/java/com/doitdo/domain/todo/repository/TodoRepository.java`

**작업:**

1. 기존 마스터의 `endDate`를 `occurrenceDate.minusDays(1)`로 줄인다.
2. 기존 마스터의 미래 파생 인스턴스를 soft delete 한다.
3. 기존 마스터 값 + `TodoUpdateReq`를 병합해 새 RECURRING 마스터를 생성한다.
4. 새 마스터의 `startDate`는 `occurrenceDate`로 고정한다.
5. 응답은 새 마스터의 `TodoDetailResp`.

주의:

- priority는 기존 마스터 priority를 우선 승계한다. 새 TODO처럼 `nextPriority`를 부여하면 화면 순서가 튈 수 있다.
- category가 body에 없으면 기존 마스터의 카테고리 스냅샷을 승계한다.
- alertTime도 body에 없으면 기존 마스터 값을 승계하고, `clearAlertTime=true`이면 null로 만든다.

### Task 7: 캘린더 가상 생성 차단 구현

**Files:**

- Modify: `src/main/java/com/doitdo/domain/todo/repository/TodoRepository.java`
- Modify: `src/main/java/com/doitdo/domain/todo/application/impl/RecurrenceServiceImpl.java`

**작업:**

1. 요청 기간 내 파생 인스턴스 마커 조회 메서드 추가.

```java
@Query("""
        SELECT t FROM Todo t
        WHERE t.userId = :userId
          AND t.masterTodoId IN :masterTodoIds
          AND t.startDate BETWEEN :from AND :to
        """)
List<Todo> findRecurringInstanceMarkers(
        @Param("userId") Long userId,
        @Param("masterTodoIds") List<Long> masterTodoIds,
        @Param("from") LocalDate from,
        @Param("to") LocalDate to);
```

2. 이 조회는 `isDeleted=false` 조건을 넣지 않는다.
3. 응답용 actual item 조회는 기존처럼 `isDeleted=false`를 유지한다.
4. 가상 인스턴스 생성 전 `masterTodoId + occurrenceDate`가 marker set에 있으면 skip한다.

### Task 8: API 문서 갱신

**Files:**

- Modify: `docs/api/swagger.md`
- Modify: `docs/api/response-format.md`
- Modify: `docs/architecture/caching.md`
- Optional Modify: `docs/plans/completed_plans/t08-recurring-calendar.md` 또는 새 completed plan

**작업:**

1. 삭제/수정 API query parameter 확장 문서화.
2. `scope=only/from/all` 의미 문서화.
3. soft-deleted NORMAL 파생 인스턴스가 recurring exception marker로 사용된다는 정책 문서화.
4. mutation cache evict 범위에 반복 scope update/delete를 명시.
5. 노션 API 기본 명세서와 BE Convention 동기화 필요 항목을 MR 설명에 남긴다.

## 7. 테스트 계획

### 단위/통합 테스트 후보

1. `scope=only` 삭제 후 같은 기간 캘린더 조회 시 해당 날짜 가상 TODO가 다시 나오지 않는다.
2. `scope=only` 삭제 후 다른 occurrence는 계속 나온다.
3. `scope=from` 삭제 후 `occurrenceDate` 이전 occurrence는 나오고 이후 occurrence는 나오지 않는다.
4. `scope=only` 수정 후 해당 날짜만 수정된 NORMAL 인스턴스로 나온다.
5. `scope=from` 수정 후 기존 마스터는 전날 종료되고 새 마스터가 `occurrenceDate`부터 나온다.
6. `scope=only/from`인데 `occurrenceDate`가 없으면 422 계열 에러가 난다.
7. 반복 규칙에 맞지 않는 `occurrenceDate`면 422 계열 에러가 난다.

### 수동 curl 시나리오

1. 월/수/금 반복 TODO 생성.
2. 캘린더 조회로 가상 occurrence 확인.
3. 수요일 occurrence `scope=only` 삭제.
4. 같은 기간 재조회해서 수요일만 사라졌는지 확인.
5. 금요일 occurrence `scope=only` 수정.
6. 재조회해서 금요일만 수정됐는지 확인.
7. 다음 주 월요일 occurrence `scope=from` 수정.
8. 재조회해서 이전 주는 기존 내용, 다음 주부터 새 내용인지 확인.

## 8. 리스크와 결정 필요 사항

| 항목 | 권장 |
|---|---|
| `scope` 값 | `only`, `from`, `all` 사용. 기존 `all`은 유지 |
| 일반 TODO에 `scope=only/from` 요청 | 기존 단건 수정/삭제처럼 처리하거나 400/422로 거절. 명확성은 거절이 낫다 |
| 하루만 수정 시 `type` 변경 | 거절 권장. 날짜 하나만 RECURRING/PERIOD로 바꾸면 의미가 흐려진다 |
| 이후 전부 수정 시 priority | 기존 마스터 priority 승계 |
| 이후 전부 수정 응답 | 새 RECURRING 마스터 반환 |

## 9. 노션 동기화 대상

현재 커넥터에서 AGENTS.md의 노션 URL은 `NOT_FOUND`로 조회되지 않았다. 구현 MR 전/후 다음 노션 문서 동기화가 필요하다.

- API 기본 명세서: TODO 삭제/수정 query parameter 확장
- BE Convention 또는 TODO 반복 정책: deleted NORMAL instance를 occurrence 삭제 마커로 쓰는 정책
- Git/JIRA Convention 변경은 없음

## 10. 완료 기준

- 새 테이블 없이 4가지 범위 동작이 모두 구현된다.
- `GET /api/todos/calendar`에서 삭제된 파생 인스턴스가 응답되지 않으면서 가상 생성은 차단한다.
- 기존 `scope=all` 삭제 동작은 깨지지 않는다.
- Swagger/docs/API 응답 문서가 실제 동작과 일치한다.
- 관련 테스트 또는 curl 검증 결과가 MR 설명에 남는다.
