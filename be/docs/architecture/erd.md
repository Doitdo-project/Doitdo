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

## 도메인 ↔ 테이블 매핑

| 도메인 | 테이블 |
|---|---|
| `auth` | refresh_tokens, auto_providers |
| `user` | users, user_wallets |
| `todo` | todos, categories, palettes, palette_colors, snooze_history |
| `tamagotchi` | characters, character_actions, character_unlocks, user_character |
| `inventory` | items, user_items |
| `shop` | purchase_logs |
| `notification` | device_tokens |
| `setting` | user_settings |

신규 테이블/도메인이 생기면 이 표를 갱신한다.

## DDL 정책

- 개발(`dev`/`local`): `spring.jpa.hibernate.ddl-auto=update` — 자동 컬럼 추가/변경.
- 운영(`prod`): `validate` 또는 마이그레이션 도구(Flyway/Liquibase) 도입을 결정 필요. 결정 전까지 운영 배포 시 수동 검토.

## 도메인 격리 — FK 처리

- 도메인 간 직접 엔티티 참조 금지.
- FK는 **Long ID 필드**로만 보관. `@ManyToOne` / `@OneToMany` 은 같은 도메인 안에서만 사용.
- 이유: 도메인 패키지 단위로 코드/테스트/배포 격리를 유지하기 위함.

상세 패키지 규약은 [`package-layout.md`](package-layout.md).
