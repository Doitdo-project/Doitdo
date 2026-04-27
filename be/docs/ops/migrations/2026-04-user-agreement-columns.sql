-- 2026-04-27 : 회원가입 약관 동의 컬럼 추가 (이용약관·개인정보처리방침·마케팅 동의)
-- 대상 DB: users 테이블
-- 기존 사용자와의 호환을 위해 NULL 허용

ALTER TABLE users
  ADD COLUMN terms_agreed_at TIMESTAMP NULL,
  ADD COLUMN privacy_agreed_at TIMESTAMP NULL,
  ADD COLUMN marketing_agreed_at TIMESTAMP NULL,
  ADD COLUMN terms_version VARCHAR(20) NULL;
