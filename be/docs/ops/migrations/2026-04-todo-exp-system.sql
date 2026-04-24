-- =============================================================================
-- Migration: TODO 완료 연동 경험치 시스템 (exp system)
-- PR: be/feat/todo-exp-system
-- 실행 대상: dev / 운영 DB 모두
-- ddl-auto=update 로 컬럼 추가는 자동 처리되지 않는 항목만 이 파일에 포함.
-- 배포 전 반드시 수동 실행 필요.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. characters 테이블: required_exp 컬럼 추가 후 데이터 채우기
--    ddl-auto=update 는 컬럼 추가를 자동 처리하지만, 데이터 UPDATE 는 수동 실행 필수.
-- -----------------------------------------------------------------------------
ALTER TABLE characters
  ADD COLUMN IF NOT EXISTS required_exp INT NULL AFTER stage;

-- 단계별 필요 경험치 기준값 (확정된 설계: EGG=0, BABY=100, TEEN=200, ADULT=300)
UPDATE characters SET required_exp = 0   WHERE stage = 'EGG';
UPDATE characters SET required_exp = 100 WHERE stage = 'BABY';
UPDATE characters SET required_exp = 200 WHERE stage = 'TEEN';
UPDATE characters SET required_exp = 300 WHERE stage = 'ADULT';

-- NOTE: NOT NULL 제약 추가는 모든 row 에 값이 채워진 것 확인 후 다음 릴리즈에서 실행.
-- MODIFY COLUMN required_exp INT NOT NULL;  -- 다음 릴리즈에서 실행

-- -----------------------------------------------------------------------------
-- 2. user_character 테이블: current_exp 추가, growth_percent 삭제
--    ddl-auto=update 가 current_exp 추가는 자동으로 하지만,
--    growth_percent DROP 은 자동으로 하지 않으므로 수동 실행 필요.
-- -----------------------------------------------------------------------------
ALTER TABLE user_character
  ADD COLUMN IF NOT EXISTS current_exp INT NOT NULL DEFAULT 0 AFTER growth_percent;

-- FE 가 growthPercent 미사용 확인됨. 기존 값 대부분 0 이라 이관 불필요.
ALTER TABLE user_character
  DROP COLUMN IF EXISTS growth_percent;

-- -----------------------------------------------------------------------------
-- 3. todos 테이블: exp_granted 컬럼 추가
--    ddl-auto=update 가 자동 추가하지만, DEFAULT FALSE 가 적용되지 않을 수 있으므로
--    명시적으로 실행 권장.
-- -----------------------------------------------------------------------------
ALTER TABLE todos
  ADD COLUMN IF NOT EXISTS exp_granted BOOLEAN NOT NULL DEFAULT FALSE AFTER is_deleted;

-- =============================================================================
-- 실행 확인 쿼리
-- =============================================================================
-- SELECT character_id, stage, required_exp FROM characters;
-- DESCRIBE user_character;
-- DESCRIBE todos;
