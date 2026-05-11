-- 뚜레딧 적립 이력 테이블 생성
-- 작성일: 2026-05-07
-- 참고: dev 환경은 spring.jpa.hibernate.ddl-auto=update 로 자동 적용됨. 운영 배포 시 수동 실행 필요.

CREATE TABLE wallet_earn_logs (
    log_id      BIGINT          NOT NULL AUTO_INCREMENT,
    user_id     BIGINT          NOT NULL,
    source      VARCHAR(30)     NOT NULL,
    amount      INT             NOT NULL,
    ref_id      BIGINT          NULL,
    earned_at   TIMESTAMP       NOT NULL,
    created_at  DATETIME(6)     NOT NULL,
    updated_at  DATETIME(6)     NOT NULL,
    PRIMARY KEY (log_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_wallet_earn_logs_user_earned ON wallet_earn_logs (user_id, earned_at);
