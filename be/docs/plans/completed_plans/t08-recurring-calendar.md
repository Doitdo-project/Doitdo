# T08 캘린더 + RECURRING 인스턴스 설계 (1차 MVP)

작성: 2026-04-22 · HeadAgent 확정

## 배경

RECURRING TODO 는 DB 에 마스터 row 1개만 존재 (type=RECURRING). 실제 발생일별 TODO 는 "인스턴스" 개념이며, 가상 인스턴스(DB 없음)와 실체 인스턴스(DB row, type=NORMAL) 로 나뉜다. 노션 T06 페이지 "반복 TODO 동작 규칙" 참고.

## 1차 MVP 범위

### 포함
1. **T08 GET /api/todos/calendar** — 실체 + 가상 인스턴스 합성 응답
2. **T05 POST /api/todos/{todoId}/snooze RECURRING 복원** — 가상 인스턴스 미루기 시 on-demand 실체화
3. **T01 DELETE /api/todos/{todoId} scope 파라미터 복원** — single (default) / all

### 제외 (후속 스테이지)
- 자정 배치 스케줄러 (지금은 on-demand 실체화만)
- 마스터 수정 → 파생 인스턴스 연쇄 업데이트 (독립 유지)
- 복잡한 반복 규칙 (요일 제외, 월 단위 등) — period 일 단위 고정

## 확정 설계 결정 (HeadAgent)

**A1 배치 없음**: `@Scheduled` 도입 안 함. 사용자 액션 시에만 가상 → 실체 변환.
**B1 요청 기간 내만 계산**: 가상 인스턴스는 T08 요청 `[from, to]` 내 발생일만 계산.
**C1 인스턴스 독립**: 마스터 수정 시 기존 실체 인스턴스는 영향 없음.

## 엔티티 변경 없음

노션 T06 "10. 제약": "자기참조 FK 없음 — 인스턴스가 어느 마스터에서 파생됐는지 DB 레벨 추적 불가"

`parent_todo_id` 같은 FK 추가하지 않는다. 추적이 필요한 곳은 `(userId, title, startDate)` heuristic 또는 별도 애플리케이션 로직으로 해결.

## API 스펙

### T08 GET /api/todos/calendar

**Query**:
- `from` (LocalDate, required) — 조회 시작일
- `to` (LocalDate, required) — 조회 종료일
- (optional 필터) `status`, `category`, `type`

**Response**: `TodoCalendarResp { List<CalendarItemResp> items }`

**CalendarItemResp 필드**:
- `todoId` (Long, nullable) — 가상 인스턴스는 null
- `masterTodoId` (Long, nullable) — RECURRING 파생에만 있음 (가상/실체화 모두)
- `occurrenceDate` (LocalDate, nullable) — RECURRING 에만 의미, NORMAL/PERIOD 는 null
- `isVirtual` (boolean) — 가상 인스턴스 여부
- `title`, `content`, `category`, `type`, `priority`, `startDate`, `endDate`, `period`, `status`, `updatedAt`, `snoozedDays`

**조회 로직**:
1. 기본 조건: `userId = current, isDeleted = false`, `startDate <= to`, `(endDate IS NULL OR endDate >= from)` 겹치는 row
2. 실체 인스턴스 + NORMAL + PERIOD 전부 위 조건으로 DB 조회
3. RECURRING 마스터들에 대해:
   - 각 마스터의 발생일 시퀀스 계산: `occurrenceDate[k] = master.startDate + (k * master.period)` for k=0,1,...
   - 조건: `from <= occurrenceDate <= to` AND (`master.endDate == null OR occurrenceDate <= master.endDate`)
   - 이미 DB 에 같은 마스터 파생 실체 인스턴스가 있는 날짜는 제외 (`(userId, title, startDate=occurrenceDate)` 매칭). 실체가 우선.
4. 합친 결과를 `occurrenceDate ASC` (RECURRING) 또는 `startDate ASC` (NORMAL/PERIOD) 로 정렬
5. 필터 `status/category/type` 는 두 집합 모두에 적용 (가상 인스턴스는 마스터 값 기반 — status 는 항상 "TODO")

**에러**:
- `T08_001` UNAUTHORIZED 자동
- `T08_002` UNPROCESSABLE — from > to, 날짜 형식 오류
- `T08_003` INTERNAL_SERVER_ERROR 자동

### T05 RECURRING 복원 (기존 T05 확장)

**Request**: `POST /api/todos/{todoId}/snooze`
- Body (optional): `{ "occurrenceDate": "2026-04-23" }`

**로직**:
- `todoId` 가 NORMAL/PERIOD → 기존 로직 (body 무시)
- `todoId` 가 RECURRING 마스터 → `occurrenceDate` 필수
  - 없으면 `T05_004` (메시지 override: "RECURRING 은 occurrenceDate 필수")
  - on-demand 실체화:
    1. 이미 같은 `(userId, master.title, startDate=occurrenceDate)` 인스턴스 있으면 그 row 사용
    2. 없으면 마스터 값 복사해 NORMAL row 생성 (title/content/categoryId/priority/alertTime 복사, type=NORMAL, status=TODO, startDate=occurrenceDate, endDate=null, period=null, isDeleted=false)
    3. 실체화된 인스턴스에 기존 snooze 로직 적용 (startDate += 1, snooze_history insert)
- 응답: `TodoDetailResp` (실체화된 인스턴스 기준)

**T05_004 메시지 재정의**: "반복 TODO 는 occurrenceDate 필수 (미제공) 또는 알 수 없는 상태" — 현재는 "반복 TODO 는 현재 미루기 미지원" → "반복 TODO 미루기 시 occurrenceDate 필수"

### T01 scope 파라미터

**Request**: `DELETE /api/todos/{todoId}?scope=single` 또는 `?scope=all`

**로직**:
- `scope` null or `single` (default): 해당 row 만 soft delete (`isDeleted = true`)
- `scope=all`:
  - todoId 가 RECURRING 마스터면 → 마스터 + 모든 파생 인스턴스 (`userId=master.userId AND title=master.title AND type=NORMAL AND isDeleted=false`) 모두 soft delete
  - todoId 가 NORMAL/PERIOD 면 → single 과 동일 (대상이 마스터가 아니라 all 의미가 없음)
- 인증/소유권 체크는 대상 row (마스터 또는 단건) 에만 적용

## 파일 변경 목록

### 신규
- `domain/todo/api/dto/req/TodoCalendarReq.java` (record: from, to, status?, category?, type?)
- `domain/todo/api/dto/req/TodoSnoozeReq.java` (record: occurrenceDate? — optional)
- `domain/todo/api/dto/resp/CalendarItemResp.java` (record: 위 필드)
- `domain/todo/api/dto/resp/TodoCalendarResp.java` (record: items)
- `domain/todo/application/impl/CalendarOccurrenceGenerator.java` (유틸: 마스터 + [from,to] → List<LocalDate>)

### 수정
- `TodoController.java`:
  - GET /calendar 추가
  - POST /{todoId}/snooze: `@RequestBody(required=false) TodoSnoozeReq req`
  - DELETE /{todoId}: `@RequestParam(required=false) String scope`
- `TodoService.java`: `calendar`, `snooze(Long, Long, TodoSnoozeReq)`, `delete(Long, Long, String scope)` 시그니처 반영
- `TodoServiceImpl.java`:
  - calendar 구현 (실체 조회 + 가상 계산 + 중복 제거 + 정렬 + 필터)
  - snooze: RECURRING 분기 추가, 실체화 로직
  - delete: scope 분기 추가
- `TodoRepository.java`:
  - 필요 시 `findByUserIdAndTitleAndStartDateAndIsDeletedFalse` 추가 (실체화 중복 방지)
  - 필요 시 `findByUserIdAndTitleAndTypeAndIsDeletedFalse` 추가 (scope=all soft delete 대상)
- `TodoSpecifications.java`: 캘린더용 `overlappingRange(from, to)` 추가 (startDate <= to AND (endDate IS NULL OR endDate >= from))
- `TodoErrorCode.java`: T05_004 메시지 재정의 (RECURRING occurrenceDate 필수)

### 테스트
- Codex 는 유닛 테스트 추가 가능하지만 필수 아님 (최종 검증은 Sonnet 의 API curl 테스트)

## 엣지 케이스

- `from > to`: T08_002 반환
- RECURRING 마스터 endDate != null, `occurrenceDate > endDate`: 제외
- period = 0 또는 음수: 엔티티 검증상 발생 안 해야 함. 방어적으로 빈 배열 반환.
- 가상 인스턴스와 실체 인스턴스 같은 날짜: 실체 우선 (중복 제거)
- 실체화 시 `(userId, title, startDate)` 매칭 인스턴스가 이미 있으면 재사용 (중복 insert 방지)
- 마스터가 soft-deleted 됐는데 요청 범위에 있는 경우: isDeleted=false 필터로 마스터 조회 자체가 안 됨 → 가상 인스턴스 생성 안 됨

## 노션 동기화 (Codex 완료 후 별도 Sonnet 에 위임)

- T08 페이지: 스펙/필터/응답 구조 반영
- T05 페이지: occurrenceDate body 추가, RECURRING 지원 설명
- T01 페이지: scope 파라미터 스펙 추가

## 위임 경계

- Codex 는 본 plan 기반으로 코드만 구현 (+ 선택적 유닛 테스트)
- curl 통합 테스트는 **Sonnet 테스트 에이전트가 별도 수행** (구현 권한 없음)
- 노션 수정은 **별도 Sonnet 에이전트** 가 본 plan 의 "노션 동기화" 섹션 기준으로 수행
