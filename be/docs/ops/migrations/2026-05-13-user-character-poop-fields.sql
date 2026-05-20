ALTER TABLE user_character
  ADD COLUMN poop_time          TIME NULL,
  ADD COLUMN poop_time_date     DATE NULL,
  ADD COLUMN poop_cleared_date  DATE NULL;

-- 기존 row 의 컬럼은 NULL 로 초기화된다.
-- 다음 GET /api/characters/me 호출 시 Asia/Seoul 기준 당일 poop_time 이 Lazy 로 결정된다.
