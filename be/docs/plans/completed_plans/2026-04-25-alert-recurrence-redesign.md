# 2026-04-25 알림/반복 도메인 재설계

## 배경
FE 팀이 3가지 변경 요청. 노션 T06/T04/T00 명세는 별도 에이전트로 동시 갱신 중.

## 회색지대 결정 (Claude 디폴트, 노션에 "검토 필요" 마커로 명시됨)
1. **startDate 검증**: `type=RECURRING` + `daysOfWeek` 가 있으면 `startDate.getDayOfWeek()` 가 `daysOfWeek` 에 포함되어야 함. 아니면 400 (`ErrorCode` 신설).
2. **endDate=null** 무한 반복 허용 (현재와 동일).
3. **snooze/배치 중복 방지**: NORMAL 인스턴스 INSERT 시 `(user_id, master_todo_id, start_date)` UNIQUE 제약. 같은 occurrenceDate 두 번 INSERT 시도 시 idempotent skip.

## 변경 항목

### 1. clearAlertTime 플래그 (T04 PATCH null=알림끄기)
- `TodoUpdateReq` 에 `Boolean clearAlertTime` 추가 (기본 false, nullable).
- `TodoServiceImpl.update()` 에서 `clearAlertTime == TRUE` 면 `todo.clearAlertTime()` 호출 (alertTime 보다 우선).
- `Todo.clearAlertTime()` 신설 (`this.alertTime = null`).
- 기존 `Todo.update()` 의 `if (alertTime != null)` 패턴은 그대로 유지 — 다른 nullable 필드(`content`, `endDate`) 의 계약 깨지 않음.
- 단위 + 통합 테스트 (`{"clearAlertTime": true}` → alertTime null, `{"alertTime": "20:00"}` → 정상 변경, 둘 다 보내면 clear 우선).

### 2. period → daysOfWeek 교체 (반복 도메인 재설계)

**DDL (`local-init/00-schema-and-seed.sql` + 마이그레이션 SQL)**
- `todos.period` 컬럼 **삭제**.
- `todos.days_of_week VARCHAR(27) DEFAULT NULL` 추가 (저장 형식: `"MON,WED,FRI"` CSV).
- 기존 RECURRING 데이터: 로컬 시드만 있고 운영 데이터 없으므로 마이그레이션 불필요. 시드 데이터는 새 형식으로 재작성.

**Entity (`Todo.java`)**
- `Integer period` 필드 제거.
- `String daysOfWeekRaw` 컬럼 + `getDaysOfWeek(): Set<DayOfWeek>` / `setDaysOfWeek(Set<DayOfWeek>)` 변환 로직 (`@Transient` 또는 컨버터).
- `Todo.create()` / `Todo.createRecurringInstance()` 시그니처 변경.
- `Todo.update()` 의 `period` 분기 → `daysOfWeek` 분기.

**DTO**
- `TodoCreateReq`: `period` → `Set<DayOfWeek> daysOfWeek` (또는 `List<String>` + 검증).
- `TodoUpdateReq`: 동일.
- `TodoDetailResp`, `CalendarItemResp`: `daysOfWeek` 노출 (RECURRING/가상 occurrence 만 의미 있음).
- 검증: `@NotEmpty` for RECURRING, 요일 ISO 3자리 대문자 (`MON, TUE, WED, THU, FRI, SAT, SUN`).

**Generator (`CalendarOccurrenceGenerator`)**
- 전면 재작성: `[from, to]` 구간을 일별 순회하며 `master.daysOfWeek` 에 포함되는 요일만 occurrence 로 반환.
- `master.endDate` 가 있으면 그 이전까지만.
- 메소드 시그니처는 가능하면 유지하되 내부 로직만 교체.

**RecurrenceServiceImpl**
- `isOccurrenceOfMaster(master, date)`: `(date - startDate) % period == 0` → `daysOfWeek.contains(date.getDayOfWeek())` (+ startDate 이상, endDate 이하 가드).
- `materializeRecurringIfNeeded()`: 동일 패턴.
- `calendar()`: 동일 (Generator 만 바뀌면 자동 반영).

### 3. 자정 배치 신규 구현 (현재 미구현, 노션 명세에는 있음)

**신규 클래스**: `RecurrenceMaterializeScheduler` (또는 적절한 패키지 위치 — `package-layout.md` 참고)
- `@Scheduled(cron = "0 0 0 * * *", zone = "Asia/Seoul")` 매일 KST 00:00.
- 동작:
  1. `type=RECURRING AND is_deleted=false` 마스터 전체 조회.
  2. 각 마스터마다 `today.dayOfWeek ∈ master.daysOfWeek` && `today >= startDate` && `(endDate == null || today <= endDate)` 검사.
  3. 통과하면 `Todo.createRecurringInstance(master, today)` INSERT.
  4. UNIQUE 제약 위반 시 idempotent skip (배치 재실행 안전).
- backfill: `last_run_date` 를 별도 테이블 또는 application property 로 보관, 누락 구간 재실행. (단순화: 배치 시작 시 today 만 처리, 누락은 다음 자정에 사용자가 캘린더 조회로 가상 occurrence 보면 됨 — 실체화는 snooze 시점 / 다음 자정 배치).
- 로그 INFO 레벨로 처리 건수 출력.

**기존 `RecurrenceServiceImpl.materializeRecurringIfNeeded()`** (snooze 시점 온디맨드 실체화) 는 유지. 자정 배치 + 온디맨드 둘 다 idempotent.

### 4. snooze/배치 중복 방지 UNIQUE 제약
- DDL: `ALTER TABLE todos ADD CONSTRAINT uk_todos_user_master_date UNIQUE (user_id, master_todo_id, start_date)` — `master_todo_id IS NOT NULL` 인 row 만 의미 있음. (MariaDB 가 NULL 다중 허용하므로 그대로 추가 OK)
- Repository INSERT 시 `DataIntegrityViolationException` catch → log warn + skip.

### 5. ErrorCode 신설
- `TODO_RECURRING_DAYS_OF_WEEK_REQUIRED` — RECURRING 인데 daysOfWeek null/empty.
- `TODO_RECURRING_START_DATE_DAY_MISMATCH` — startDate 의 요일이 daysOfWeek 에 미포함.

## 영향 파일 (예상)
- `local-init/00-schema-and-seed.sql` (DDL + 시드)
- `src/main/java/.../todo/domain/Todo.java`
- `src/main/java/.../todo/domain/TodoRepository.java` (alert 쿼리 daysOfWeek 사용)
- `src/main/java/.../todo/dto/TodoCreateReq.java`
- `src/main/java/.../todo/dto/TodoUpdateReq.java`
- `src/main/java/.../todo/dto/TodoDetailResp.java`
- `src/main/java/.../todo/dto/CalendarItemResp.java`
- `src/main/java/.../todo/service/TodoServiceImpl.java`
- `src/main/java/.../todo/recurrence/RecurrenceServiceImpl.java`
- `src/main/java/.../todo/recurrence/CalendarOccurrenceGenerator.java`
- `src/main/java/.../todo/scheduler/RecurrenceMaterializeScheduler.java` (신규)
- `src/main/java/.../common/error/ErrorCode.java`
- `docs/api/error-codes.md` (신설된 에러 코드)
- `docs/architecture/package-layout.md` (신규 scheduler)
- 테스트 파일들

## 작업 순서
1. ErrorCode + DDL 변경 + Entity 변경
2. DTO 변경
3. Generator + RecurrenceServiceImpl 매칭 로직 교체
4. clearAlertTime 추가
5. RecurrenceMaterializeScheduler 신설
6. UNIQUE 제약
7. 기존 테스트 수정 + 신규 테스트 추가
8. `./gradlew clean build` 통과 확인
9. docs/api/, docs/architecture/ 동기화

## 제약
- 빌드/테스트 통과 후 보고. 통과 못 하면 그 상태에서 멈추고 보고.
- `./scripts/apply-dev-stack.sh` 자동 실행 절대 금지.
- `./scripts/check.sh` 는 검증용으로 자동 실행 OK.
- 노션은 별도 에이전트가 갱신 완료 (T06/T04/T00 모두 daysOfWeek/clearAlertTime/alertTime 반영 끝).
- JIRA 신규 이슈 S14P31D107-368~377 가 이 작업 범위 (참고만, 상태 변경은 사용자가 함).

## CDP MCP 금지
CDP MCP(Chrome DevTools Protocol MCP)는 절대 사용하지 않는다. 브라우저 자동화, DOM 접근, 스크린샷 등 CDP 관련 도구 일체 금지.
