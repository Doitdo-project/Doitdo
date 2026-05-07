-- 다마고치 터치 적립 상태 컬럼 추가
-- 작성일: 2026-05-07
-- 참고: dev 환경은 spring.jpa.hibernate.ddl-auto=update 로 자동 적용됨. 운영 배포 시 수동 실행 필요.

ALTER TABLE user_character
  ADD COLUMN last_touched_at TIMESTAMP NULL,
  ADD COLUMN daily_touch_count INT NOT NULL DEFAULT 0,
  ADD COLUMN daily_touch_date DATE NULL;
