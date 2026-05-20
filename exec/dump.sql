-- 시연용: 이메일 계정의 현재 활성 캐릭터를 즉시 진화/독립 가능 상태로 만든다.
-- BABY/TEEN: current_exp = required_exp, farewell_available_at = NULL
-- ADULT: current_exp = required_exp, farewell_available_at = 현재시간 - 1분
UPDATE user_character uc
JOIN users u ON u.user_id = uc.user_id
JOIN characters c ON c.character_id = uc.character_id
SET uc.current_exp = c.required_exp,
    uc.farewell_available_at =
      CASE
        WHEN c.stage = 'ADULT' THEN DATE_SUB(NOW(), INTERVAL 1 MINUTE)
        ELSE NULL
      END
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0
  AND uc.is_active = 1
  AND uc.is_deleted = 0
  AND c.required_exp > 0;

-------------------

USE doitdo;

UPDATE user_character uc
JOIN users u ON u.user_id = uc.user_id
JOIN characters c ON c.character_id = uc.character_id
SET uc.current_exp = c.required_exp,
    uc.farewell_available_at =
      CASE
        WHEN c.stage = 'ADULT' THEN DATE_SUB(NOW(), INTERVAL 1 MINUTE)
        ELSE NULL
      END
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0
  AND uc.is_active = 1
  AND uc.is_deleted = 0
  AND c.required_exp > 0;


  ---------------------------------------

  USE doitdo;

SET SQL_SAFE_UPDATES = 0;

UPDATE user_character uc
JOIN users u ON u.user_id = uc.user_id
JOIN characters c ON c.character_id = uc.character_id
SET uc.current_exp = c.required_exp,
    uc.farewell_available_at =
      CASE
        WHEN c.stage = 'ADULT' THEN DATE_SUB(NOW(), INTERVAL 1 MINUTE)
        ELSE NULL
      END
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0
  AND uc.is_active = 1
  AND uc.is_deleted = 0
  AND c.required_exp > 0;

SET SQL_SAFE_UPDATES = 1;



---------------
---todo 모두 삭제----
USE doitdo;

SET SQL_SAFE_UPDATES = 0;

UPDATE todos t
JOIN users u ON u.user_id = t.user_id
SET t.is_deleted = 1
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0
  AND t.is_deleted = 0;

SET SQL_SAFE_UPDATES = 1;


SELECT
  COUNT(*) AS total_todos,
  SUM(CASE WHEN t.is_deleted = 0 THEN 1 ELSE 0 END) AS active_todos,
  SUM(CASE WHEN t.is_deleted = 1 THEN 1 ELSE 0 END) AS deleted_todos
FROM todos t
JOIN users u ON u.user_id = t.user_id
WHERE u.email = 'gms07051@gmail.com';

-----------------------

USE doitdo;

SET SQL_SAFE_UPDATES = 0;

-- 기존 카테고리 전체 제거
DELETE c
FROM categories c
JOIN users u ON u.user_id = c.user_id
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0;

-- 기본 카테고리 5개 재생성
INSERT INTO categories (user_id, category_name, color_id)
SELECT u.user_id, v.category_name, pc.color_id
FROM users u
JOIN (
  SELECT '공부' AS category_name, 1 AS color_order
  UNION ALL SELECT '운동', 2
  UNION ALL SELECT '업무', 3
  UNION ALL SELECT '집안일', 4
  UNION ALL SELECT '기타', 5
) v
JOIN palettes p ON p.palette_id = (
  SELECT p2.palette_id
  FROM palettes p2
  ORDER BY p2.display_order ASC
  LIMIT 1
)
JOIN palette_colors pc
  ON pc.palette_id = p.palette_id
 AND pc.color_order = v.color_order
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0;

SET SQL_SAFE_UPDATES = 1;


------------
--todo채우기용
USE doitdo;

SET SQL_SAFE_UPDATES = 0;

UPDATE todos t
JOIN users u ON u.user_id = t.user_id
SET t.is_deleted = 1
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0
  AND t.is_deleted = 0;

INSERT INTO todos (
  user_id, category_id,
  title, content, type, status, done_date, first_completed_date,
  priority, alert_time, start_date, end_date,
  master_todo_id, recurrence_group_id, days_of_week,
  is_deleted, exp_granted, created_at, updated_at
)
WITH RECURSIVE dates AS (
  SELECT DATE('2026-05-01') AS d
  UNION ALL
  SELECT DATE_ADD(d, INTERVAL 1 DAY)
  FROM dates
  WHERE d < DATE('2026-05-21')
),
items AS (
  SELECT 1 AS slot, '공부' AS category_name, '알고리즘 1문제 풀기' AS title, '오늘의 문제 풀이와 오답 정리' AS content, '09:00' AS alert_time
  UNION ALL SELECT 2, '업무', '시연 체크리스트 확인', '기능별 시연 흐름 점검', '10:30'
  UNION ALL SELECT 3, '운동', '산책 20분', '가볍게 걷고 컨디션 관리', '18:30'
  UNION ALL SELECT 4, '집안일', '책상 정리', '작업 공간 정리하기', '21:00'
)
SELECT
  u.user_id,
  c.category_id,
  CONCAT(DATE_FORMAT(d.d, '%c/%e'), ' ', i.title),
  i.content,
  'NORMAL',
  CASE WHEN d.d < DATE('2026-05-19') THEN 'DONE' ELSE 'TODO' END,
  CASE WHEN d.d < DATE('2026-05-19') THEN d.d ELSE NULL END,
  CASE WHEN d.d < DATE('2026-05-19') THEN d.d ELSE NULL END,
  i.slot,
  i.alert_time,
  d.d,
  NULL,
  NULL,
  NULL,
  NULL,
  0,
  CASE WHEN d.d < DATE('2026-05-19') THEN 1 ELSE 0 END,
  NOW(),
  NOW()
FROM dates d
JOIN items i
JOIN users u ON u.email = 'gms07051@gmail.com' AND u.is_deleted = 0
JOIN categories c ON c.user_id = u.user_id AND c.category_name = i.category_name;

INSERT INTO todos (
  user_id, category_id,
  title, content, type, status, done_date, first_completed_date,
  priority, alert_time, start_date, end_date,
  master_todo_id, recurrence_group_id, days_of_week,
  is_deleted, exp_granted, created_at, updated_at
)
SELECT u.user_id, c.category_id,
       p.title, p.content, 'PERIOD',
       CASE WHEN p.end_date < DATE('2026-05-19') THEN 'DONE' ELSE 'TODO' END,
       CASE WHEN p.end_date < DATE('2026-05-19') THEN p.end_date ELSE NULL END,
       CASE WHEN p.end_date < DATE('2026-05-19') THEN p.end_date ELSE NULL END,
       p.priority, p.alert_time, p.start_date, p.end_date,
       NULL, NULL, NULL,
       0,
       CASE WHEN p.end_date < DATE('2026-05-19') THEN 1 ELSE 0 END,
       NOW(), NOW()
FROM users u
JOIN (
  SELECT '업무' category_name, '발표 자료 초안 만들기' title, '핵심 화면 캡처와 순서 정리' content, DATE('2026-05-01') start_date, DATE('2026-05-03') end_date, 1 priority, '14:00' alert_time
  UNION ALL SELECT '업무', 'API 테스트 케이스 정리', '주요 성공/실패 케이스 점검', '2026-05-02', '2026-05-06', 2, '15:00'
  UNION ALL SELECT '공부', 'CS 개념 복습 주간', '네트워크/DB/운영체제 정리', '2026-05-05', '2026-05-09', 3, '20:00'
  UNION ALL SELECT '업무', '피드백 반영', '테스터 피드백 확인 및 정리', '2026-05-08', '2026-05-12', 4, '16:00'
  UNION ALL SELECT '기타', '앱스토어 이미지 정리', '스크린샷 문구와 순서 확인', '2026-05-10', '2026-05-14', 5, '13:00'
  UNION ALL SELECT '업무', '최종 발표 스크립트 작성', '시연 멘트와 역할 분담 정리', '2026-05-13', '2026-05-17', 6, '19:00'
  UNION ALL SELECT '업무', '시연 동선 점검', '로그인부터 캐릭터 독립까지 리허설', '2026-05-15', '2026-05-19', 7, '11:00'
  UNION ALL SELECT '기타', '배포 체크리스트 확인', '환경변수와 서버 상태 확인', '2026-05-18', '2026-05-21', 8, '17:00'
) p
JOIN categories c ON c.user_id = u.user_id AND c.category_name = p.category_name
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0;

INSERT INTO todos (
  user_id, category_id,
  title, content, type, status, done_date, first_completed_date,
  priority, alert_time, start_date, end_date,
  master_todo_id, recurrence_group_id, days_of_week,
  is_deleted, exp_granted, created_at, updated_at
)
SELECT u.user_id, c.category_id,
       r.title, r.content, 'RECURRING', 'TODO', NULL, NULL,
       r.priority, r.alert_time, r.start_date, r.end_date,
       NULL, NULL, r.days_of_week,
       0, 0, NOW(), NOW()
FROM users u
JOIN (
  SELECT '운동' category_name, '매일 아침 스트레칭' title, '하루 시작 전 10분 스트레칭' content, DATE('2026-05-01') start_date, DATE('2026-05-21') end_date, 'MON,TUE,WED,THU,FRI,SAT,SUN' days_of_week, 1 priority, '08:00' alert_time
  UNION ALL SELECT '공부', '평일 알고리즘 복습', '어제 푼 문제 다시 보기', '2026-05-01', '2026-05-21', 'MON,TUE,WED,THU,FRI', 2, '09:30'
  UNION ALL SELECT '업무', '평일 Jira 확인', '진행 중 이슈와 오늘 작업 확인', '2026-05-01', '2026-05-21', 'MON,TUE,WED,THU,FRI', 3, '10:00'
  UNION ALL SELECT '운동', '월수금 산책', '저녁 산책 20분', '2026-05-01', '2026-05-21', 'MON,WED,FRI', 4, '18:00'
  UNION ALL SELECT '공부', '화목 CS 정리', '면접 질문 3개 정리', '2026-05-01', '2026-05-21', 'TUE,THU', 5, '20:30'
  UNION ALL SELECT '집안일', '토요일 방 청소', '바닥과 책상 정리', '2026-05-01', '2026-05-21', 'SAT', 6, '11:00'
  UNION ALL SELECT '기타', '일요일 주간 회고', '이번 주 완료한 일 돌아보기', '2026-05-01', '2026-05-21', 'SUN', 7, '21:00'
) r
JOIN categories c ON c.user_id = u.user_id AND c.category_name = r.category_name
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0;

SET SQL_SAFE_UPDATES = 1;




---
---스트릭5일

USE doitdo;

UPDATE user_streaks us
JOIN users u ON u.user_id = us.user_id
SET us.current_streak_count = 5,
    us.current_streak_start_date = DATE_SUB(CURDATE(), INTERVAL 4 DAY),
    us.last_active_date = CURDATE(),
    us.longest_streak_count = GREATEST(us.longest_streak_count, 5),
    us.longest_streak_start_date = DATE_SUB(CURDATE(), INTERVAL 4 DAY),
    us.longest_streak_end_date = CURDATE()
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0;



---도감초기화
USE doitdo;

SET SQL_SAFE_UPDATES = 0;

DELETE cu
FROM character_unlocks cu
JOIN users u ON u.user_id = cu.user_id
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0;

SET SQL_SAFE_UPDATES = 1;


---알로 가기 기존꺼 소프트딜리트하고 
USE doitdo;

SET @email = 'gms07051@gmail.com';

SET SQL_SAFE_UPDATES = 0;

-- 기존 현재 캐릭터 비활성화
UPDATE user_character uc
JOIN users u ON u.user_id = uc.user_id
SET uc.is_active = 0,
    uc.is_deleted = 1,
    uc.updated_at = NOW()
WHERE u.email = @email
  AND u.is_deleted = 0
  AND uc.is_active = 1
  AND uc.is_deleted = 0;

-- 새 알 생성: 랜덤 EGG 중 하나
INSERT INTO user_character (
  user_id, character_id, equiped_items_id, name,
  current_exp, is_active, is_deleted,
  farewell_available_at, last_touched_at,
  daily_touch_count, daily_touch_date,
  poop_time, poop_time_date, poop_cleared_date,
  farewell_notified,
  created_at, updated_at
)
SELECT u.user_id, c.character_id, NULL, c.name,
       0, 1, 0,
       NULL, NULL,
       0, NULL,
       NULL, NULL, NULL,
       0,
       NOW(), NOW()
FROM users u
JOIN characters c ON c.stage = 'EGG'
WHERE u.email = @email
  AND u.is_deleted = 0
ORDER BY RAND()
LIMIT 1;

SET SQL_SAFE_UPDATES = 1;




---가구 미보유로 바꾸기
USE doitdo;

SET SQL_SAFE_UPDATES = 0;

-- 기본 배경 제외한 배치 제거
DELETE rfp
FROM room_furniture_placements rfp
JOIN user_furnitures uf ON uf.user_furniture_id = rfp.user_furniture_id
JOIN users u ON u.user_id = uf.user_id
JOIN furnitures f ON f.furniture_id = uf.furniture_id
WHERE u.email = 'gms07051@gmail.com'
  AND f.code <> 'DEFAULT_BACKGROUND';

-- 기본 배경 제외한 보유 가구 제거
DELETE uf
FROM user_furnitures uf
JOIN users u ON u.user_id = uf.user_id
JOIN furnitures f ON f.furniture_id = uf.furniture_id
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0
  AND f.code <> 'DEFAULT_BACKGROUND';

SET SQL_SAFE_UPDATES = 1;




----시연 3개 투두 만들기
USE doitdo;

INSERT INTO todos (
  user_id, category_id,
  title, content, type, status, done_date, first_completed_date,
  priority, alert_time, start_date, end_date,
  master_todo_id, recurrence_group_id, days_of_week,
  is_deleted, exp_granted, created_at, updated_at
)
SELECT u.user_id, c.category_id,
       v.title, v.content, v.type, 'TODO', NULL, NULL,
       v.priority, NULL, v.start_date, NULL,
       NULL, NULL, NULL,
       0, 0, NOW(), NOW()
FROM users u
JOIN categories c
  ON c.user_id = u.user_id
 AND c.category_name = '기타'
JOIN (
  SELECT
    '투두 완료하고 크레딧 받아보기' AS title,
    '예시 투두예요. 완료하면 크레딧이 쌓여요. 필요 없으면 삭제해도 괜찮아요.' AS content,
    'NORMAL' AS type,
    DATE('2026-05-21') AS start_date,
    1 AS priority
  UNION ALL
  SELECT
    '키우고 싶은 다마고치 떠올려보기',
    '예시 투두예요. 언젠가 하고 싶은 일을 자유롭게 적어보세요.',
    'SOMEDAY',
    NULL,
    2
  UNION ALL
  SELECT
    '오늘 할 일 하나 완료하기',
    '캐릭터 경험치와 보상 흐름을 확인하기 위한 투두예요.',
    'NORMAL',
    DATE('2026-05-21'),
    3
) v
WHERE u.email = 'gms07051@gmail.com'
  AND u.is_deleted = 0;