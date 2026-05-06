-- todos 입력 길이 정책 적용 (title 20자, content 100자)
-- JIRA S14P31D107-466 (S14P31D107-464 흡수)
-- 작성일: 2026-04-30
-- 참고: dev 환경은 spring.jpa.hibernate.ddl-auto=update 로 자동 적용됨. 운영 배포 시 수동 실행 필요.

-- ============================================================
-- [배포 전 반드시 실행] 운영 DB 점검 SQL
-- 아래 쿼리에서 위반 건수가 0 이 아니면 배포 STOP 후 데이터 정제 필수.
-- ============================================================
-- SELECT MAX(LENGTH(title))   AS max_title,
--        MAX(LENGTH(content))  AS max_content
-- FROM todos;
--
-- SELECT COUNT(*) AS title_over  FROM todos WHERE LENGTH(title)   > 20;
-- SELECT COUNT(*) AS content_over FROM todos WHERE LENGTH(content) > 100;
-- ============================================================

ALTER TABLE todos MODIFY COLUMN title   VARCHAR(20)  NOT NULL;
ALTER TABLE todos MODIFY COLUMN content VARCHAR(100) NULL;
