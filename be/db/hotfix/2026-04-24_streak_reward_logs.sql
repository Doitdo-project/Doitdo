CREATE TABLE IF NOT EXISTS streak_reward_logs (
    streak_reward_log_id BIGINT NOT NULL AUTO_INCREMENT COMMENT '스트릭 보상 로그 ID',
    user_id BIGINT NOT NULL COMMENT '사용자 ID',
    streak_start_date DATE NOT NULL COMMENT '스트릭 시작일',
    streak_count INT NOT NULL COMMENT '보상 대상 스트릭 수',
    reward_amount INT NOT NULL COMMENT '보상 두레딧',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성 일시',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
    PRIMARY KEY (streak_reward_log_id),
    CONSTRAINT uk_streak_reward_logs_segment UNIQUE (user_id, streak_start_date, streak_count),
    CONSTRAINT fk_users_to_streak_reward_logs FOREIGN KEY (user_id) REFERENCES users(user_id)
);
