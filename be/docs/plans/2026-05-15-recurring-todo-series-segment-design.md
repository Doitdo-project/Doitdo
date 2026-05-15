# Recurring TODO Series Segment Design

## 배경

현재 `scope=from` 반복 TODO 수정은 기존 RECURRING 마스터의 `endDate` 를 기준일 전날로 줄이고,
기준일부터 새 RECURRING 마스터를 생성한다.

예를 들어 `task1 5/1~5/30` 을 `5/15 이후 task2` 로 수정하면 DB 상으로는 다음처럼 분리된다.

| 구간 | 제목 | 마스터 |
|---|---|---|
| 5/1 ~ 5/14 | task1 | old master |
| 5/15 ~ 5/30 | task2 | new master |

문제는 두 마스터를 같은 반복 흐름으로 묶는 식별자가 없어서,
이후 `5/13 이후 수정/삭제` 를 수행해도 `5/15~5/30 task2` 구간까지 반영할 수 없다는 점이다.

## 목표

- 같은 반복에서 파생된 RECURRING 마스터들을 하나의 그룹으로 묶는다.
- `scope=from` 수정/삭제는 같은 그룹 안에서 기준일 이후와 겹치는 구간 전체에 반영한다.
- 기준일보다 앞선 과거 구간은 보존한다.
- 긴 반복 기간 안에서 여러 번 `scope=from` 수정이 발생해도 구간 단위로 안정적으로 처리한다.

## 비목표

- 반복 TODO 가상 occurrence 생성 방식 자체는 변경하지 않는다.
- 완료/진행 중 상태의 수정 제한 정책은 변경하지 않는다.
- `scope=only`, `scope=all` 의 외부 API 의미는 변경하지 않는다.

## 데이터 모델

`todos` 테이블에 `recurrence_group_id` 컬럼을 추가한다.

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `recurrence_group_id` | BIGINT NULL | 같은 반복 흐름을 묶는 그룹 ID |

정책:

- RECURRING 마스터는 항상 `recurrence_group_id` 를 가진다.
- 최초 반복 생성 시 저장 후 자기 `todoId` 를 `recurrence_group_id` 로 사용한다.
- `scope=from` 으로 새 마스터를 만들 때 기존 마스터의 `recurrence_group_id` 를 유지한다.
- 반복 파생 NORMAL 인스턴스도 마스터의 `recurrence_group_id` 를 복사한다.
- 일반 TODO 는 `NULL` 로 둔다.

조회 성능을 위해 `(user_id, recurrence_group_id, is_deleted, start_date, end_date)` 성격의 인덱스를 추가한다.

## 구간 처리 규칙

같은 `recurrence_group_id` 에 속한 RECURRING 마스터 row 하나를 "구간 마스터"로 본다.

예시:

| 구간 | 제목 | group |
|---|---|---|
| 1/1 ~ 3/9 | task1 | 1 |
| 3/10 ~ 5/19 | task2 | 1 |
| 5/20 ~ 8/4 | task3 | 1 |
| 8/5 ~ 12/31 | task4 | 1 |

`5/15 이후 수정` 결과:

| 구간 | 제목 |
|---|---|
| 1/1 ~ 3/9 | task1 |
| 3/10 ~ 5/14 | task2 |
| 5/15 ~ 12/31 | 수정값 |

처리 순서:

1. 요청 마스터의 `recurrence_group_id` 를 구한다.
2. 같은 그룹에서 기준일 이후와 겹치는 활성 RECURRING 마스터들을 조회한다.
3. 기준일을 포함하는 마스터는 `endDate = 기준일 - 1` 로 자른다.
4. 기준일 이후에 시작하는 마스터들은 soft delete 한다.
5. 삭제/수정 대상 마스터들의 기준일 이후 파생 NORMAL 인스턴스도 soft delete 한다.
6. 수정이면 기준일부터 기존 그룹의 가장 늦은 종료일까지 새 RECURRING 마스터를 생성한다.

## 삭제 동작

`scope=from` 삭제는 같은 그룹의 기준일 이후 구간을 제거한다.

예시:

| 기존 | 결과 |
|---|---|
| task1 5/1~5/9 | 유지 |
| task2 5/10~5/19 | 5/10~5/14 만 유지 |
| task3 5/20~5/30 | 삭제 |

기준일이 `5/15` 면 최종적으로 `5/1~5/14` 까지만 남는다.

## 수정 동작

`scope=from` 수정은 삭제 동작과 같은 방식으로 기준일 이후 구간을 비운 뒤,
수정값을 가진 새 RECURRING 마스터를 기준일부터 생성한다.

새 마스터의 종료일은 다음 우선순위를 따른다.

1. 요청 body 의 `endDate`
2. 같은 그룹에서 기준일 이후와 겹쳤던 마스터들의 가장 늦은 `endDate`
3. 기존 요청 마스터의 `endDate`

## 영향 파일

- `Todo.java`
  - `recurrenceGroupId` 필드 추가
  - 반복 생성/파생 인스턴스 생성 시 그룹 ID 유지
- `TodoRepository.java`
  - 같은 그룹의 기준일 이후 겹침 마스터 조회 추가
  - 같은 그룹/마스터들의 기준일 이후 파생 인스턴스 조회 추가
- `TodoServiceImpl.java`
  - create 후 RECURRING 마스터의 그룹 ID 초기화
  - `delete(scope=from)` 구간 처리 변경
  - `updateRecurringFrom()` 구간 처리 변경
- DB migration
  - `todos.recurrence_group_id` 추가
  - 기존 RECURRING 마스터는 자기 `todo_id` 로 백필
  - 기존 반복 파생 NORMAL 인스턴스는 `master_todo_id` 로 백필

## 테스트 시나리오

- `task1 5/1~5/30` 생성 후 `5/15 이후 task2` 수정 시 같은 `recurrenceGroupId` 유지.
- `task1 5/1~5/30` -> `5/10 이후 task2` -> `5/20 이후 task3` 후 `5/15 이후 수정` 시 `task2`, `task3` 구간만 반영.
- 위 상태에서 `5/15 이후 삭제` 시 `5/1~5/14` 만 남음.
- 기준일 이후에 materialize 된 NORMAL 인스턴스도 함께 soft delete 됨.
