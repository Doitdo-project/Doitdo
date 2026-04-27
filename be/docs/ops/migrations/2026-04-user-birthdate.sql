-- 2026-04-27 : 회원가입 생년월일 컬럼 추가 (만 14세 미만 가입 차단 대응)
-- 대상 DB: users 테이블
-- 기존 사용자와의 호환을 위해 NULL 허용

ALTER TABLE users ADD COLUMN birth_date DATE NULL;
