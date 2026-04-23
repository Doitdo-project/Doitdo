-- =====================================================================
-- HOTFIX: 2026-04-23
-- 사고: dev DB의 auto_providers 에 같은 (provider, provider_uid) 가 두 row
--       (provider_id=3,4 / GOOGLE / 115316207117491188873) 존재하여
--       OAuthServiceImpl.loginWithGoogle 의 findByProviderAndProviderUid 가
--       IncorrectResultSizeDataAccessException(2 results) 발생.
--       또한 user_id 13, 14 가 users 테이블에 없는 orphan 상태로 부속 테이블
--       (refresh_tokens, user_settings, user_wallets, auto_providers) 에만
--       잔존하여 데이터 정합성 깨짐.
--
-- 처치:
--   1) user_id 13, 14 관련 부속 row 정리
--   2) auto_providers (provider, provider_uid) UNIQUE 인덱스 추가
--      (엔티티는 @UniqueConstraint 로 동기화 — AutoProvider.java 참조)
--
-- 근본 원인 (TODO, 후속 작업):
--   - OAuthServiceImpl.signupWithGoogle 의 트랜잭션 경계 점검
--   - 가입 흐름의 idempotency 보강 (findByProviderAndProviderUid 선조회 후
--     이미 매핑된 경우 신규 user/auto_provider 생성 막기)
--   - users ↔ auto_providers 등 부속 테이블 FK CASCADE 정책 정리
-- =====================================================================

START TRANSACTION;

-- 1) orphan 정리 (user_id 13, 14)
DELETE FROM refresh_tokens WHERE user_id IN (13, 14);
DELETE FROM user_settings  WHERE user_id IN (13, 14);
DELETE FROM user_wallets   WHERE user_id IN (13, 14);
DELETE FROM auto_providers WHERE provider_id IN (3, 4);

COMMIT;

-- 2) UNIQUE 인덱스 추가
ALTER TABLE auto_providers
    ADD UNIQUE KEY uk_provider_uid (provider, provider_uid);
