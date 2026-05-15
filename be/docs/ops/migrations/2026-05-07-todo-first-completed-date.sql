-- TODO 최초 완료일 컬럼 추가
-- 작성일: 2026-05-07
-- 참고: dev 환경은 spring.jpa.hibernate.ddl-auto=update 로 자동 적용됨. 운영 배포 시 수동 실행 필요.

ALTER TABLE todos
    ADD COLUMN first_completed_date DATE NULL;

UPDATE todos
SET first_completed_date = COALESCE(done_date, DATE(created_at))
WHERE status = 'DONE'
  AND first_completed_date IS NULL;
