-- 버그 신고 테이블 생성
-- JIRA S14P31D107-442
-- 작성일: 2026-04-30
-- 참고: dev 환경은 spring.jpa.hibernate.ddl-auto=update 로 자동 적용됨. 운영 배포 시 수동 실행 필요.

CREATE TABLE IF NOT EXISTS bug_reports (
    bug_report_id BIGINT NOT NULL AUTO_INCREMENT,
    user_id       BIGINT NOT NULL,
    title         VARCHAR(100) NOT NULL,
    content       VARCHAR(500) NOT NULL,
    is_deleted    TINYINT(1) NOT NULL DEFAULT 0,
    status        ENUM('NEW','REVIEWING','COMPLETE') NOT NULL DEFAULT 'NEW',
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (bug_report_id),
    INDEX idx_bug_reports_user_id (user_id)
);
