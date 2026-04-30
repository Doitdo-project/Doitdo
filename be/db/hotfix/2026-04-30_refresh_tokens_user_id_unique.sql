-- =====================================================================
-- HOTFIX: 2026-04-30
-- 사고: dev DB의 refresh_tokens 에 같은 user_id (=8, eric728066@gmail.com)
--       row 가 거의 동시(약 1ms 차이)에 2개 INSERT 되어 이후
--       OAuthServiceImpl.saveOrUpdateRefreshToken 의 findByUserId 가
--       NonUniqueResultException → POST /api/auth/social/GOOGLE 500.
--
-- 원인: SELECT-then-INSERT 패턴의 race condition.
--       동시 요청 두 트랜잭션이 모두 SELECT 에서 empty 를 보고
--       각자 INSERT 에 성공 → 같은 user_id 로 row 2개.
--       refresh_tokens 테이블에 user_id UNIQUE 가 없어 DB 가 막아주지도 못함.
--
-- 처치:
--   1) user_id 별 중복 row 정리 (가장 최근 expires_at 만 남기고 나머지 삭제)
--   2) refresh_tokens (user_id) UNIQUE 인덱스 추가
--      (엔티티는 @UniqueConstraint 로 동기화 — RefreshToken.java 참조)
--
-- 코드 변경 (같은 PR):
--   - RefreshTokenRepository.upsertByUserId 추가 (ON DUPLICATE KEY UPDATE)
--   - OAuthServiceImpl, AuthServiceImpl 의 saveOrUpdateRefreshToken 을
--     upsert 단일 statement 로 교체 → race 제거
--   - findByUserId → findFirstByUserId (잔존 dupe 대비 defensive)
-- =====================================================================

START TRANSACTION;

-- 1) user_id 당 중복 row 정리 — 가장 최근 expires_at(동률 시 token_id 큰 것) 만 보존.
DELETE rt
FROM refresh_tokens rt
JOIN (
    SELECT user_id, MAX(token_id) AS keep_token_id
    FROM (
        SELECT user_id, token_id,
               ROW_NUMBER() OVER (
                   PARTITION BY user_id
                   ORDER BY expires_at DESC, token_id DESC
               ) AS rn
        FROM refresh_tokens
    ) ranked
    WHERE ranked.rn = 1
    GROUP BY user_id
) keepers ON keepers.user_id = rt.user_id
WHERE rt.token_id <> keepers.keep_token_id;

COMMIT;

-- 2) UNIQUE 인덱스 추가
ALTER TABLE refresh_tokens
    ADD UNIQUE KEY uk_user_id (user_id);
