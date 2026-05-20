-- 가구 테마 테이블 생성 + 기존 가구 theme_code 백필
-- 작성일: 2026-05-14
--
-- 적용 시점: 테마 목록/테마 미리보기 API 배포 전 실행 권장.
--
-- 본 파일이 처리하는 것:
--   1) furniture_themes 테이블 생성
--   2) furnitures.theme_code 컬럼 추가
--   3) 23개 테마 seed 입력
--   4) 기존 CATEGORY_THEME 형식 code 기반으로 furnitures.theme_code 백필
--   5) BACKGROUND 가구 thumbnail_url 로 테마 대표 이미지 보정

CREATE TABLE IF NOT EXISTS furniture_themes (
    theme_code    VARCHAR(30) NOT NULL,
    theme_name    VARCHAR(50) NOT NULL,
    thumbnail_url VARCHAR(500) NULL,
    display_order INT NOT NULL DEFAULT 0,
    is_active     TINYINT(1) NOT NULL DEFAULT 1,
    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (theme_code),
    INDEX idx_furniture_themes_active_order (is_active, display_order)
);

ALTER TABLE furnitures
    ADD COLUMN IF NOT EXISTS theme_code VARCHAR(30) NULL AFTER category;

START TRANSACTION;

INSERT INTO furniture_themes (
    theme_code,
    theme_name,
    thumbnail_url,
    display_order,
    is_active,
    created_at,
    updated_at
) VALUES
    ('AUTUMN', '가을', NULL, 1, 1, NOW(), NOW()),
    ('CHERRY', '벚꽃', NULL, 2, 1, NOW(), NOW()),
    ('CLASSIC', '클래식', NULL, 3, 1, NOW(), NOW()),
    ('CYBER', '사이버', NULL, 4, 1, NOW(), NOW()),
    ('DAISY', '데이지', NULL, 5, 1, NOW(), NOW()),
    ('DESERT', '사막', NULL, 6, 1, NOW(), NOW()),
    ('FOREST', '숲', NULL, 7, 1, NOW(), NOW()),
    ('GOTHIC', '고딕', NULL, 8, 1, NOW(), NOW()),
    ('HEART', '하트', NULL, 9, 1, NOW(), NOW()),
    ('HONEY', '허니', NULL, 10, 1, NOW(), NOW()),
    ('LAVENDER', '라벤더', NULL, 11, 1, NOW(), NOW()),
    ('LEAF', '잎', NULL, 12, 1, NOW(), NOW()),
    ('MAPLE', '단풍', NULL, 13, 1, NOW(), NOW()),
    ('MARINE', '마린', NULL, 14, 1, NOW(), NOW()),
    ('MOON', '달빛', NULL, 15, 1, NOW(), NOW()),
    ('OCEAN', '바다', NULL, 16, 1, NOW(), NOW()),
    ('PINE', '소나무', NULL, 17, 1, NOW(), NOW()),
    ('RAINBOW', '무지개', NULL, 18, 1, NOW(), NOW()),
    ('SAGE', '세이지', NULL, 19, 1, NOW(), NOW()),
    ('SNOW', '눈', NULL, 20, 1, NOW(), NOW()),
    ('SOLAR', '태양', NULL, 21, 1, NOW(), NOW()),
    ('STRAWBERRY', '딸기', NULL, 22, 1, NOW(), NOW()),
    ('VINTAGE', '빈티지', NULL, 23, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
    theme_name = VALUES(theme_name),
    display_order = VALUES(display_order),
    is_active = VALUES(is_active),
    updated_at = NOW();

UPDATE furnitures f
JOIN furniture_themes t
    ON t.theme_code = SUBSTRING_INDEX(f.code, '_', -1)
SET f.theme_code = t.theme_code
WHERE f.code <> 'DEFAULT_BACKGROUND'
  AND f.code LIKE '%\_%';

UPDATE furnitures
SET theme_code = NULL
WHERE code = 'DEFAULT_BACKGROUND';

UPDATE furniture_themes t
JOIN furnitures f
    ON f.theme_code = t.theme_code
   AND f.category = 'BACKGROUND'
   AND f.is_deleted = 0
SET t.thumbnail_url = f.thumbnail_url,
    t.updated_at = NOW()
WHERE f.thumbnail_url IS NOT NULL
  AND f.thumbnail_url <> ''
  AND (t.thumbnail_url IS NULL OR t.thumbnail_url = '');

COMMIT;

CREATE INDEX IF NOT EXISTS idx_furnitures_theme_code
    ON furnitures (theme_code);

CREATE UNIQUE INDEX IF NOT EXISTS uk_furnitures_theme_category
    ON furnitures (theme_code, category);

-- 검증
-- SELECT theme_code, theme_name, display_order, is_active, thumbnail_url
-- FROM furniture_themes
-- ORDER BY display_order, theme_code;
--
-- SELECT theme_code, COUNT(*) AS cnt, GROUP_CONCAT(DISTINCT category ORDER BY category) AS categories
-- FROM furnitures
-- WHERE theme_code IS NOT NULL
-- GROUP BY theme_code
-- ORDER BY theme_code;
