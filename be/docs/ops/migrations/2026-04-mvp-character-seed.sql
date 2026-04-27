-- =============================================================================
-- Seed: MVP character data
-- 실행 대상: 운영 DB 초기 세팅
-- 포함 범위: DUCK / ELEPHANT / HALLABONG / RACCOON
-- 제외 범위: CAT / NEMO / SCALLION / SHRIMP / PANDA
-- =============================================================================

START TRANSACTION;

INSERT INTO characters
  (character_id, created_at, updated_at, species, thumbnail_url, stage, name, required_exp)
VALUES
  (4, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'DUCK', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/duck/duck-baby.png', 'BABY', '아기 오리', 100),
  (5, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'DUCK', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/duck/duck-teen.png', 'TEEN', '오리', 200),
  (6, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'DUCK', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/duck/duck-adult.png', 'ADULT', '어른 오리', 300),
  (7, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'ELEPHANT', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/elephant/elephant-baby.png', 'BABY', '아기 코끼리', 100),
  (8, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'ELEPHANT', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/elephant/elephant-teen.png', 'TEEN', '코끼리', 200),
  (9, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'ELEPHANT', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/elephant/elephant-adult.png', 'ADULT', '어른 코끼리', 300),
  (10, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'HALLABONG', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/hallabong/hallabong-baby.png', 'BABY', '아기 한라봉', 100),
  (11, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'HALLABONG', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/hallabong/hallabong-teen.png', 'TEEN', '한라봉', 200),
  (12, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'HALLABONG', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/hallabong/hallabong-adult.png', 'ADULT', '어른 한라봉', 300),
  (16, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'RACCOON', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/raccoon-baby.png', 'BABY', '아기 너구리', 100),
  (17, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'RACCOON', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/raccoon-teen.png', 'TEEN', '너구리', 200),
  (18, '2026-04-23 15:46:38.000000', '2026-04-23 15:46:38.000000', 'RACCOON', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/raccoon-adult.png', 'ADULT', '어른 너구리', 300),
  (26, '2026-04-23 15:47:44.000000', '2026-04-23 15:47:44.000000', 'DUCK', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/temp5.png', 'EGG', '오리 알', 0),
  (27, '2026-04-23 15:47:44.000000', '2026-04-23 15:47:44.000000', 'ELEPHANT', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/temp5.png', 'EGG', '코끼리 알', 0),
  (28, '2026-04-23 15:47:44.000000', '2026-04-23 15:47:44.000000', 'HALLABONG', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/temp5.png', 'EGG', '한라봉 씨앗', 0),
  (30, '2026-04-23 15:47:44.000000', '2026-04-23 15:47:44.000000', 'RACCOON', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/temp5.png', 'EGG', '너구리 알', 0)
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  species = VALUES(species),
  thumbnail_url = VALUES(thumbnail_url),
  stage = VALUES(stage),
  name = VALUES(name),
  required_exp = VALUES(required_exp);

INSERT INTO character_actions
  (action_id, character_id, created_at, updated_at, action_type, action_url)
VALUES
  (1, 4, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/duck/actions/baby/eye.gif'),
  (2, 4, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/duck/actions/baby/idle.gif'),
  (3, 5, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/duck/actions/teen/eye.gif'),
  (4, 5, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/duck/actions/teen/idle.gif'),
  (5, 6, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/duck/actions/adult/eye.gif'),
  (6, 6, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/duck/actions/adult/idle.gif'),
  (7, 7, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/elephant/actions/baby/eye.gif'),
  (8, 7, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/elephant/actions/baby/idle.gif'),
  (9, 8, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/elephant/actions/teen/eye.gif'),
  (10, 8, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/elephant/actions/teen/idle.gif'),
  (11, 9, '2026-04-27 10:27:48.521548', '2026-04-27 10:35:45.273422', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/elephant/actions/adult/eye_2.gif'),
  (12, 9, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/elephant/actions/adult/eye.gif'),
  (13, 9, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/elephant/actions/adult/idle.gif'),
  (14, 10, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/hallabong/actions/baby/eye.gif'),
  (15, 10, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/hallabong/actions/baby/idle.gif'),
  (16, 11, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/hallabong/actions/teen/eye.gif'),
  (17, 11, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/hallabong/actions/teen/idle.gif'),
  (18, 12, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/hallabong/actions/adult/eye.gif'),
  (19, 12, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/hallabong/actions/adult/idle.gif'),
  (22, 16, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/actions/baby/eye.gif'),
  (23, 16, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/actions/baby/idle.gif'),
  (24, 17, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/actions/teen/eye.gif'),
  (25, 17, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/actions/teen/idle.gif'),
  (26, 18, '2026-04-27 10:27:48.521548', '2026-04-27 10:35:45.273422', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/actions/adult/eye_2.gif'),
  (27, 18, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'EYE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/actions/adult/eye.gif'),
  (28, 18, '2026-04-27 10:27:48.521548', '2026-04-27 10:35:45.273422', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/actions/adult/idle_2.gif'),
  (29, 18, '2026-04-27 10:27:48.521548', '2026-04-27 10:27:48.521548', 'IDLE', 'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/characters/raccoon/actions/adult/idle.gif')
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  character_id = VALUES(character_id),
  action_type = VALUES(action_type),
  action_url = VALUES(action_url);

INSERT INTO character_species_backgrounds
  (species, created_at, updated_at, birth_background)
VALUES
  ('DUCK', '2026-04-24 12:32:48.000000', '2026-04-24 12:32:48.000000', '뒤뚱뒤뚱 걸으면서도 할 일만큼은 꼬박꼬박 해내는 성실함의 상징. 겉으론 여유로워 보여도 물밑에선 누구보다 바쁘게 발을 젓는다. "하루에 한 걸음이라도 앞으로"가 평생의 모토인 꾸준함의 대명사.'),
  ('ELEPHANT', '2026-04-24 12:32:48.000000', '2026-04-24 12:32:48.000000', '한 번 세운 약속은 절대 잊지 않는 기억력의 왕. 작은 할 일도 코끝에 매듭처럼 기록해두고, 몇 년이 지나도 그날의 다짐을 떠올린다. 느리지만 묵직하게, 가장 큰 꿈을 가장 오래 완주하는 듬직한 친구.'),
  ('HALLABONG', '2026-04-24 12:32:48.000000', '2026-04-24 12:32:48.000000', '제주 바람과 햇살을 먹고 자란 감귤 정령. 새콤달콤한 성격처럼 하루의 목표도 알록달록하게 세운다. 껍질 속 작은 알갱이들처럼 큰 목표를 잘게 나눠 차근차근 해치우는 것이 특기인 분할정복의 달인.'),
  ('RACCOON', '2026-04-24 12:32:48.000000', '2026-04-24 12:32:48.000000', '손끝이 야무져 어떤 일이든 꼼꼼히 챙기는 세심함의 대명사. 쓰레기통에서 보물을 찾아내듯 하루의 자투리 시간에서도 의미를 길어 올린다. "놓치는 것 없이 오늘을 정리한다"가 모토인 작은 정리왕.')
ON DUPLICATE KEY UPDATE
  updated_at = VALUES(updated_at),
  birth_background = VALUES(birth_background);

COMMIT;

-- 실행 확인 쿼리
-- SELECT species, GROUP_CONCAT(stage ORDER BY FIELD(stage, 'EGG', 'BABY', 'TEEN', 'ADULT')) AS stages FROM characters GROUP BY species ORDER BY species;
-- SELECT c.species, c.stage, COUNT(a.action_id) AS action_count FROM characters c LEFT JOIN character_actions a ON a.character_id = c.character_id WHERE c.stage IN ('BABY', 'TEEN', 'ADULT') GROUP BY c.species, c.stage ORDER BY c.species, FIELD(c.stage, 'BABY', 'TEEN', 'ADULT');
-- SELECT species FROM character_species_backgrounds ORDER BY species;
