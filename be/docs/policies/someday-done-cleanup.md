# SOMEDAY DONE 노출 만료 정책

## 정책

`type=SOMEDAY` TODO 가 `status=DONE` 으로 변경되면 `done_date` 에 KST 기준 완료일을 저장한다.
`GET /api/todos` 목록 조회는 `SOMEDAY + DONE + done_date < 오늘(KST)` 인 항목을 응답에서 제외한다.

## 적용 범위

- 적용: `GET /api/todos`
- 미적용: `GET /api/todos/search`, `GET /api/todos/calendar`
- 미적용 타입: `NORMAL`, `PERIOD`, `RECURRING`

## 데이터 규칙

- 신규 컬럼: `todos.done_date DATE NULL`
- `TODO` 또는 `IN_PROGRESS` 에서 `DONE` 으로 전이할 때 `done_date = LocalDate.now(Asia/Seoul)`
- `DONE` 에서 다른 상태로 되돌릴 때 `done_date = NULL`
- `DONE` 에서 `DONE` 으로 유지될 때 기존 `done_date` 유지
- 기존 데이터는 백필하지 않는다. `done_date IS NULL` 인 기존 `SOMEDAY DONE` 항목은 계속 노출한다.

## 운영 주의

- 마이그레이션은 컬럼 추가만 수행한다.
- 인덱스는 추가하지 않는다.
- 서버 기본 timezone 에 의존하지 않고 `ZoneId.of("Asia/Seoul")` 기준 날짜를 사용한다.
