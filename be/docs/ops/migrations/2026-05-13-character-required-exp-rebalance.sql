-- 캐릭터 단계별 required_exp 재조정
-- 작성일: 2026-05-13
-- 정책: BABY=75, TEEN=100, ADULT=125, EGG=0 유지
-- 참고: 기존 활성 user_character 가 새 기준에 도달/초과한 경우 다음 단계로 자동 승급하고 current_exp 는 0 으로 리셋한다.

START TRANSACTION;

-- 1. characters.required_exp 일괄 갱신
UPDATE characters
SET required_exp = 75
WHERE stage = 'BABY';

UPDATE characters
SET required_exp = 100
WHERE stage = 'TEEN';

UPDATE characters
SET required_exp = 125
WHERE stage = 'ADULT';

-- 2-1. BABY 단계 활성 캐릭터 중 current_exp >= 75 인 row -> 같은 species 의 TEEN 으로 승급
UPDATE user_character uc
JOIN characters c ON uc.character_id = c.character_id
SET uc.character_id = (
    SELECT c2.character_id
    FROM characters c2
    WHERE c2.species = c.species
      AND c2.stage = 'TEEN'
    ORDER BY c2.character_id ASC
    LIMIT 1
),
    uc.current_exp = 0
WHERE c.stage = 'BABY'
  AND uc.current_exp >= 75
  AND uc.is_active = TRUE
  AND uc.is_deleted = FALSE;

-- 2-2. TEEN 단계 활성 캐릭터 중 current_exp >= 100 인 row -> 같은 species 의 ADULT 로 승급
UPDATE user_character uc
JOIN characters c ON uc.character_id = c.character_id
SET uc.character_id = (
    SELECT c2.character_id
    FROM characters c2
    WHERE c2.species = c.species
      AND c2.stage = 'ADULT'
    ORDER BY c2.character_id ASC
    LIMIT 1
),
    uc.current_exp = 0
WHERE c.stage = 'TEEN'
  AND uc.current_exp >= 100
  AND uc.is_active = TRUE
  AND uc.is_deleted = FALSE;

-- 2-3. ADULT 단계는 자동 처리하지 않는다.
--      canFarewell 판정은 service 단에서 current_exp >= required_exp 로 자연스럽게 켜진다.

COMMIT;
