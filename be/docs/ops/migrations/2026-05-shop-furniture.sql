-- 상점 가구 1차 MVP 테이블 생성
-- 작성일: 2026-05-04
-- 참고: dev 환경은 spring.jpa.hibernate.ddl-auto=update 로 자동 적용됨. 운영 배포 시 수동 실행 필요.

CREATE TABLE IF NOT EXISTS furnitures (
    furniture_id  BIGINT NOT NULL AUTO_INCREMENT,
    code          VARCHAR(50) NOT NULL,
    name          VARCHAR(100) NOT NULL,
    description   VARCHAR(255) NULL,
    category      VARCHAR(30) NOT NULL,
    price         INT NOT NULL,
    image_url     VARCHAR(500) NULL,
    thumbnail_url VARCHAR(500) NULL,
    default_x     INT NOT NULL,
    default_y     INT NOT NULL,
    width         INT NOT NULL,
    height        INT NOT NULL,
    z_index       INT NOT NULL,
    is_on_sale    TINYINT(1) NOT NULL DEFAULT 1,
    is_deleted    TINYINT(1) NOT NULL DEFAULT 0,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (furniture_id),
    UNIQUE KEY uk_furnitures_code (code),
    INDEX idx_furnitures_category (category)
);

CREATE TABLE IF NOT EXISTS user_furnitures (
    user_furniture_id BIGINT NOT NULL AUTO_INCREMENT,
    user_id           BIGINT NOT NULL,
    furniture_id      BIGINT NOT NULL,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_furniture_id),
    UNIQUE KEY uk_user_furnitures_user_furniture (user_id, furniture_id),
    INDEX idx_user_furnitures_user_id (user_id)
);

CREATE TABLE IF NOT EXISTS furniture_purchase_logs (
    purchase_id            BIGINT NOT NULL AUTO_INCREMENT,
    user_id                BIGINT NOT NULL,
    user_furniture_id      BIGINT NOT NULL,
    furniture_id           BIGINT NOT NULL,
    price                  INT NOT NULL,
    balance_after_purchase INT NOT NULL,
    purchased_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (purchase_id),
    INDEX idx_furniture_purchase_logs_user_id (user_id),
    INDEX idx_furniture_purchase_logs_furniture_id (furniture_id)
);

CREATE TABLE IF NOT EXISTS room_furniture_placements (
    placement_id      BIGINT NOT NULL AUTO_INCREMENT,
    user_id           BIGINT NOT NULL,
    user_furniture_id BIGINT NOT NULL,
    x                 INT NOT NULL,
    y                 INT NOT NULL,
    z_index           INT NOT NULL,
    rotation          INT NOT NULL DEFAULT 0,
    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (placement_id),
    INDEX idx_room_furniture_placements_user_id (user_id),
    INDEX idx_room_furniture_placements_user_furniture_id (user_furniture_id)
);
