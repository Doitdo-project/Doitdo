-- 기본 배경 가구 seed
-- S3 업로드 예정 경로:
-- - furniture/background/default_background.webp

INSERT INTO furnitures (
    code,
    name,
    description,
    category,
    price,
    image_url,
    thumbnail_url,
    default_x,
    default_y,
    width,
    height,
    z_index,
    is_on_sale,
    is_deleted,
    created_at,
    updated_at
) VALUES
    (
        'DEFAULT_BACKGROUND',
        '기본 배경',
        '신규 사용자 기본 배경',
        'BACKGROUND',
        0,
        'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/furniture/background/default_background.webp',
        'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/furniture/background/default_background.webp',
        0,
        0,
        390,
        640,
        0,
        0,
        0,
        NOW(),
        NOW()
    )
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    description = VALUES(description),
    image_url = VALUES(image_url),
    thumbnail_url = VALUES(thumbnail_url),
    updated_at = NOW();
