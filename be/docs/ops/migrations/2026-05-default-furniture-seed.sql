-- 기본 벽지/바닥 가구 seed
-- S3 업로드 예정 경로:
-- - furniture/wall/default_wall.webp
-- - furniture/floor/default_floor.webp

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
        'DEFAULT_WALL',
        '기본 벽지',
        '신규 사용자 기본 벽지',
        'WALL',
        0,
        'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/furniture/wall/default_wall.webp',
        'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/furniture/wall/default_wall.webp',
        0,
        0,
        390,
        420,
        0,
        0,
        0,
        NOW(),
        NOW()
    ),
    (
        'DEFAULT_FLOOR',
        '기본 바닥',
        '신규 사용자 기본 바닥',
        'FLOOR',
        0,
        'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/furniture/floor/default_floor.webp',
        'https://doitdo-s3.s3.ap-northeast-2.amazonaws.com/furniture/floor/default_floor.webp',
        0,
        420,
        390,
        220,
        1,
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
