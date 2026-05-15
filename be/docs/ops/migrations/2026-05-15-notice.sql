-- 공지사항 테이블 생성
-- 작성일: 2026-05-15
--
-- 적용 시점: 공지사항 조회/다시 안보기 API 배포 전 실행.
-- 공지 등록은 관리자 API 없이 DB 직접 INSERT 로 처리한다.

CREATE TABLE IF NOT EXISTS notices (
    notice_id  BIGINT NOT NULL AUTO_INCREMENT,
    title      VARCHAR(100) NOT NULL,
    content    TEXT NOT NULL,
    is_active  TINYINT(1) NOT NULL DEFAULT 1,
    started_at DATETIME NULL,
    ended_at   DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (notice_id),
    INDEX idx_notices_active_window_created (is_active, started_at, ended_at, created_at, notice_id)
);

CREATE TABLE IF NOT EXISTS notice_dismissals (
    notice_dismissal_id BIGINT NOT NULL AUTO_INCREMENT,
    user_id             BIGINT NOT NULL,
    notice_id           BIGINT NOT NULL,
    created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (notice_dismissal_id),
    UNIQUE KEY uk_notice_dismissals_user_notice (user_id, notice_id),
    INDEX idx_notice_dismissals_notice_id (notice_id)
);

-- 예시 seed
-- INSERT INTO notices (title, content, is_active, started_at, ended_at)
-- VALUES ('서비스 점검 안내', '오늘 23시에 서비스 점검이 있습니다.', 1, NOW(), NULL);
