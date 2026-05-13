# 캐릭터 EXP 단계별 재조정 — Stage 3

- **작성일:** 2026-05-13
- **MR 단위:** Stage 3 단독 MR (`[BE : feat] 캐릭터 레벨업 EXP 재조정`)
- **브랜치:** `be/feat/character-exp-rebalance` (origin/dev `88b5706` 에서 분기)
- **선행:** Stage 1 (머지), Stage 2 (머지)
- **후속:** Stage 4 (일일 똥치우기)

---

## 1. 정책 변경

| 단계 | 현재 required_exp | 신규 required_exp |
|------|---|---|
| BABY → TEEN | 100 | **75** |
| TEEN → ADULT | 200 | **100** |
| ADULT (farewell) | 300 | **125** |

> TODO 완료 1회 EXP 보상은 그대로 (3~7 random, `ExpCalculator.rollTodoDoneExp`).

---

## 2. 변경 명세

### 2.1 DB seed (`local-init/00-schema-and-seed.sql`)

`characters` 테이블의 `required_exp` 값 일괄 갱신:

```sql
-- 모든 종(species) × 모든 stage 행에 대해
UPDATE characters SET required_exp = 75  WHERE stage = 'BABY';
UPDATE characters SET required_exp = 100 WHERE stage = 'TEEN';
UPDATE characters SET required_exp = 125 WHERE stage = 'ADULT';
```

> seed 파일 자체의 INSERT 값을 새 정책으로 직접 수정. 별도 UPDATE 문 추가 X (seed 는 매번 fresh 적용이므로).

### 2.2 운영 DB 마이그레이션 (`docs/ops/migrations/2026-05-13-character-required-exp-rebalance.sql`)

신규 마이그레이션 SQL 파일:

```sql
-- 1. characters.required_exp 일괄 갱신
UPDATE characters SET required_exp = 75  WHERE stage = 'BABY';
UPDATE characters SET required_exp = 100 WHERE stage = 'TEEN';
UPDATE characters SET required_exp = 125 WHERE stage = 'ADULT';

-- 2. 기존 진행 중 user_character 자동 승급
--    정책: required_exp 도달/초과 시 다음 단계로 승급, 남은 EXP 소멸 (expProgress=0)
--    BABY(75) → TEEN, TEEN(100) → ADULT
--    ADULT 는 farewell 액션 별개라 자동 승급 안 함 (canFarewell flag 만 자연스럽게 켜짐)

-- 2-1. BABY 단계에서 expProgress >= 75 인 사용자 → TEEN 으로 승급
UPDATE user_character uc
JOIN characters c ON uc.character_id = c.character_id
SET uc.character_id = (
    SELECT c2.character_id FROM characters c2
    WHERE c2.species = c.species AND c2.stage = 'TEEN'
    LIMIT 1
),
uc.exp_progress = 0
WHERE c.stage = 'BABY' AND uc.exp_progress >= 75;

-- 2-2. TEEN 단계에서 expProgress >= 100 인 사용자 → ADULT 로 승급
UPDATE user_character uc
JOIN characters c ON uc.character_id = c.character_id
SET uc.character_id = (
    SELECT c2.character_id FROM characters c2
    WHERE c2.species = c.species AND c2.stage = 'ADULT'
    LIMIT 1
),
uc.exp_progress = 0
WHERE c.stage = 'TEEN' AND uc.exp_progress >= 100;

-- 2-3. ADULT 단계는 자동 처리하지 않음
--      (canFarewell 판정은 service 단에서 expProgress >= requiredExp 로 자연스럽게 켜짐)
```

> **정확한 컬럼명·테이블명·species/stage 식별 방식**은 Codex 가 entity·repository 코드 읽고 확정한다. 위 SQL 은 의도 표현용 의사코드.

### 2.3 Character 엔티티 (`src/main/java/com/doitdo/domain/tamagotchi/entity/Character.java`)

- `required_exp` 컬럼 매핑 그대로 유지 (`requiredExp` 필드)
- 코드 변경 없음 (값은 DB 가 보유)

### 2.4 ExpCalculator (`src/main/java/com/doitdo/domain/tamagotchi/application/ExpCalculator.java`)

- `rollTodoDoneExp()` 그대로 유지 (3~7 random)
- 변경 없음 (단계별 cap 만 변경됨)

### 2.5 진화/farewell 로직 (`TamagotchiServiceImpl`)

- **현재 로직 그대로**: `expProgress >= requiredExp` 면 `canEvolve` 또는 `canFarewell` true 반환
- 코드 변경 없이 정책값(`requiredExp`) 만 바뀐 효과로 동작

---

## 3. 통합 테스트

**파일:** `src/test/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImplTest.java` (또는 별도 통합 테스트)

| Case | 시나리오 | 기대 결과 |
|------|---------|---------|
| 1 | BABY 단계 사용자, EXP 74 → TODO 완료 (+5) → 79 | canEvolve=true (75 초과) |
| 2 | BABY 단계 사용자, evolve 호출 | TEEN 으로 승급, expProgress=0, requiredExp=100 |
| 3 | TEEN 단계 사용자, EXP 99 → TODO 완료 (+5) → 104 | canEvolve=true |
| 4 | TEEN 단계 사용자, evolve 호출 | ADULT 로 승급, expProgress=0, requiredExp=125 |
| 5 | ADULT 단계 사용자, EXP 124 → TODO 완료 (+5) → 129 | canFarewell=true |

> 기존 EXP 100/200/300 검증하던 테스트가 있으면 75/100/125 로 갱신.

### 마이그레이션 단위 테스트 (선택)

기존 진행 중 user_character 자동 승급 로직 검증을 별도 테스트로:
- 신규 정책 적용 전 BABY expProgress=80 인 row → 마이그레이션 후 TEEN expProgress=0
- 신규 정책 적용 전 TEEN expProgress=120 인 row → 마이그레이션 후 ADULT expProgress=0

> 마이그레이션 테스트는 시간 비용 크면 생략 가능. 핵심은 SQL 정확성 (수동 검수).

---

## 4. docs 갱신

| 문서 | 갱신 내용 |
|------|---------|
| `docs/architecture/erd.md` | `characters.required_exp` 의 기본값/정책 설명 갱신 (75/100/125) |
| `docs/api/error-codes.md` | 신규 코드 없음. 기존 캐릭터 진화 관련 코드 설명만 정책값 갱신 |
| `docs/ops/migrations/2026-05-13-character-required-exp-rebalance.sql` | 신규 마이그레이션 파일 (위 2.2) |
| `docs/plans/completed_plans/2026-05-07-doredit-earning-system-design.md` | "Stage 3 EXP 재조정 반영" 주석 |

---

## 5. 영향 파일 전체 목록

### 수정
- `local-init/00-schema-and-seed.sql` — characters seed required_exp 값
- (테스트) `src/test/java/com/doitdo/domain/tamagotchi/application/impl/TamagotchiServiceImplTest.java` — 단계별 EXP assertion 갱신
- `docs/architecture/erd.md`
- `docs/plans/2026-05-07-doredit-earning-system-design.md`

### 신규
- `docs/ops/migrations/2026-05-13-character-required-exp-rebalance.sql`
- (선택) 마이그레이션 단위 테스트

### 코드 변경 없음
- `Character.java`, `ExpCalculator.java`, `TamagotchiServiceImpl.java`, `UserCharacter.java` — DB 값만 바뀌고 코드 로직은 그대로

---

## 6. 완료 기준 (DoD)

1. `local-init/00-schema-and-seed.sql` 의 characters seed required_exp 값 갱신 (75/100/125)
2. 마이그레이션 SQL 파일 작성 (운영 DB 적용용)
3. 통합/단위 테스트의 기존 EXP assertion (100/200/300) 갱신 (75/100/125)
4. `./gradlew test` 전체 통과
5. `./gradlew build` 통과
6. docs 동시 갱신
7. 커밋 메시지: `feat: 캐릭터 단계별 required_exp 재조정 (75/100/125)`

---

## 7. 작업하지 않는 것 (Out of Scope)

- ExpCalculator 의 TODO 완료 EXP 보상 변경 (3~7 random 그대로)
- 진화/farewell 로직 자체 변경
- ADULT 단계 자동 farewell 처리 (사용자 액션 그대로)
- Stage 4 (일일 똥치우기)

---

## 8. 제약 (Codex 위임 시 필수)

CDP MCP(Chrome DevTools Protocol MCP)는 절대 사용하지 않는다. 브라우저 자동화, DOM 접근, 스크린샷 등 CDP 관련 도구 일체 금지.
