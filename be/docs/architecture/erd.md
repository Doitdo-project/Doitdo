# ERD / 스키마

## 원본 자료

- 전체 ERD: [`../imgs/erd.png`](../imgs/erd.png)
- 테이블별 분할: `docs/imgs/tables/{테이블명}.png` (17장)

테이블 이미지 직접 링크 (가나다순):

| 테이블 | 이미지 |
|---|---|
| auto_providers | [tables/auto_providers.png](../imgs/tables/auto_providers.png) |
| categories | [tables/categories.png](../imgs/tables/categories.png) |
| character_actions | [tables/character_actions.png](../imgs/tables/character_actions.png) |
| character_unlocks | [tables/character_unlocks.png](../imgs/tables/character_unlocks.png) |
| characters | [tables/characters.png](../imgs/tables/characters.png) |
| device_tokens | [tables/device_tokens.png](../imgs/tables/device_tokens.png) |
| items | [tables/items.png](../imgs/tables/items.png) |
| palette_colors | [tables/palette_colors.png](../imgs/tables/palette_colors.png) |
| palettes | [tables/palettes.png](../imgs/tables/palettes.png) |
| purchase_logs | [tables/purchase_logs.png](../imgs/tables/purchase_logs.png) |
| refresh_tokens | [tables/refresh_tokens.png](../imgs/tables/refresh_tokens.png) |
| todos | [tables/todos.png](../imgs/tables/todos.png) |
| user_character | [tables/user_character.png](../imgs/tables/user_character.png) |
| user_items | [tables/user_items.png](../imgs/tables/user_items.png) |
| user_settings | [tables/user_settings.png](../imgs/tables/user_settings.png) |
| user_wallets | [tables/user_wallets.png](../imgs/tables/user_wallets.png) |
| users | [tables/users.png](../imgs/tables/users.png) |
| wallet_earn_logs | 신규 테이블 (2026-05-07) |

## 도메인 ↔ 테이블 매핑

| 도메인 | 테이블 |
|---|---|
| `auth` | refresh_tokens, auto_providers |
| `user` | users, user_wallets, wallet_earn_logs |
| `todo` | todos, categories, palettes, palette_colors, snooze_history |
| `tamagotchi` | characters, character_actions, character_unlocks, user_character |
| `inventory` | items, user_items |
| `shop` | purchase_logs, furnitures, user_furnitures, furniture_purchase_logs, room_furniture_placements |
| `notification` | device_tokens |
| `setting` | user_settings |
| `bugreport` | bug_reports |

신규 테이블/도메인이 생기면 이 표를 갱신한다.

## todo 도메인 변경 컬럼

| 테이블 | 컬럼 | 비고 |
|---|---|---|
| `todos` | `first_completed_date DATE NULL` | TODO 완료 1개당 20 뚜레딧 적립 계산용 최초 완료일. 취소·재완료 시 보존 |
| `todos` | `category_name VARCHAR(10) NULL` | 카테고리 이름 스냅샷. rename 시 전파, 삭제 시 잔여. 필터/응답의 카테고리 매칭 키. |
| `todos` | `category_color_id INT NULL` | 카테고리 색상(`palette_colors.color_id`) 스냅샷. 동일 이름의 활성 카테고리가 있으면 응답 시 그 색이 override. |
| `todos` | `idx_todos_list_category_name` | 인덱스 `(user_id, is_deleted, category_name, start_date, todo_id)` — 이름 기반 필터 lookup. |

## user 도메인 추가 테이블 (뚜레딧 적립 이력)

| 테이블 | 주요 컬럼 | 비고 |
|---|---|---|
| `wallet_earn_logs` | `log_id`, `user_id`, `source`, `amount`, `ref_id`, `earned_at`, `created_at`, `updated_at` | 뚜레딧 적립 출처별 감사 로그 및 일일 cap 합산 기준 |

`wallet_earn_logs.source` enum 값:

- `SIGNUP_BONUS`
- `STREAK_7DAY`
- `PET_TOUCH`
- `TODO_COMPLETION`
- `DAILY_ATTENDANCE`

보상 정책 (2026-05-13 Stage 1 개정 + Stage 5 출석 자동 적립 반영):

| source | 금액 | 일일 한도 | 비고 |
|---|---:|---:|---|
| `SIGNUP_BONUS` | 100 | 없음 | `bypassDailyCap=true` |
| `STREAK_7DAY` | 500 | 없음 | 7일 단위 스트릭 보상, `bypassDailyCap=true` |
| `PET_TOUCH` | 50 | 2회 / 100 | 쿨타임 2시간 |
| `TODO_COMPLETION` | 20 | 5회 / 100 | 당일 보상 대상 TODO 1개 완료당 1회 |
| `DAILY_ATTENDANCE` | 100 | 1회 / 100 | `GET /api/users/me` 호출 시 자동 적립, `bypassDailyCap=true`, Asia/Seoul 자정 기준 |

`PET_TOUCH` + `TODO_COMPLETION` 합산 일일 한도는 200 뚜레딧이다. `DAILY_ATTENDANCE` 는 `wallet_earn_logs` 당일 SUM 조회로 자동 적립 여부를 판단하고, 이 합산 cap 에 포함하지 않는다.

## tamagotchi 도메인 변경 컬럼 (다마고치 터치 적립)

| 테이블 | 컬럼 | 타입 | 비고 |
|---|---|---|---|
| `user_character` | `last_touched_at` | `TIMESTAMP NULL` | 마지막 터치 적립 성공 시각 |
| `user_character` | `daily_touch_count` | `INT NOT NULL DEFAULT 0` | 해당 일자 터치 적립 성공 횟수 |
| `user_character` | `daily_touch_date` | `DATE NULL` | `daily_touch_count` 기준 일자 |

## DDL 정책

- 개발(`dev`/`local`): `spring.jpa.hibernate.ddl-auto=update` — 자동 컬럼 추가/변경.
- 운영(`prod`): `validate` 또는 마이그레이션 도구(Flyway/Liquibase) 도입을 결정 필요. 결정 전까지 운영 배포 시 수동 검토.

## 도메인 격리 — FK 처리

- 도메인 간 직접 엔티티 참조 금지.
- FK는 **Long ID 필드**로만 보관. `@ManyToOne` / `@OneToMany` 은 같은 도메인 안에서만 사용.
- 이유: 도메인 패키지 단위로 코드/테스트/배포 격리를 유지하기 위함.

상세 패키지 규약은 [`package-layout.md`](package-layout.md).
