-- 얼씨 / 네온 팔레트 기본 팔레트 치환 후 삭제
-- 작성일: 2026-05-15
--
-- 적용 시점: dev/prod 모두 팔레트 목록에서 얼씨, 네온 제거가 필요할 때 실행.
-- 처리 방식:
--   1) 얼씨/네온 색상을 참조 중인 categories, todos 스냅샷을 기본 팔레트의 같은 color_order 색으로 치환
--   2) 더 이상 참조되지 않는 얼씨/네온 palette_colors 삭제
--   3) 색상이 모두 삭제된 얼씨/네온 palettes 삭제

START TRANSACTION;

CREATE TEMPORARY TABLE tmp_palette_color_remap AS
SELECT
    src_pc.color_id AS source_color_id,
    dst_pc.color_id AS target_color_id,
    src_p.palette_name,
    src_pc.color_order
FROM palettes src_p
JOIN palette_colors src_pc
    ON src_pc.palette_id = src_p.palette_id
JOIN palettes dst_p
    ON dst_p.palette_name = '기본'
JOIN palette_colors dst_pc
    ON dst_pc.palette_id = dst_p.palette_id
   AND dst_pc.color_order = src_pc.color_order
WHERE src_p.palette_name IN ('얼씨', '네온');

-- 사전 확인: 남아 있으면 아래 UPDATE 후 기본 팔레트로 치환되어야 하는 참조.
SELECT
    r.palette_name,
    r.color_order,
    r.source_color_id,
    r.target_color_id,
    COUNT(DISTINCT c.category_id) AS category_ref_count,
    COUNT(DISTINCT t.todo_id) AS todo_snapshot_ref_count
FROM tmp_palette_color_remap r
LEFT JOIN categories c
    ON c.color_id = r.source_color_id
LEFT JOIN todos t
    ON t.category_color_id = r.source_color_id
GROUP BY r.palette_name, r.color_order, r.source_color_id, r.target_color_id
ORDER BY r.palette_name, r.color_order;

UPDATE categories c
JOIN tmp_palette_color_remap r
    ON r.source_color_id = c.color_id
SET c.color_id = r.target_color_id;

UPDATE todos t
JOIN tmp_palette_color_remap r
    ON r.source_color_id = t.category_color_id
SET t.category_color_id = r.target_color_id;

DELETE pc
FROM palette_colors pc
JOIN palettes p
    ON p.palette_id = pc.palette_id
WHERE p.palette_name IN ('얼씨', '네온')
  AND NOT EXISTS (
      SELECT 1
      FROM categories c
      WHERE c.color_id = pc.color_id
  )
  AND NOT EXISTS (
      SELECT 1
      FROM todos t
      WHERE t.category_color_id = pc.color_id
  );

DELETE p
FROM palettes p
WHERE p.palette_name IN ('얼씨', '네온')
  AND NOT EXISTS (
      SELECT 1
      FROM palette_colors pc
      WHERE pc.palette_id = p.palette_id
  );

-- 검증: 결과가 0행이어야 얼씨/네온 팔레트 삭제 완료.
SELECT
    p.palette_id,
    p.palette_name,
    pc.color_id,
    pc.color_order,
    COUNT(DISTINCT c.category_id) AS category_ref_count,
    COUNT(DISTINCT t.todo_id) AS todo_snapshot_ref_count
FROM palettes p
LEFT JOIN palette_colors pc
    ON pc.palette_id = p.palette_id
LEFT JOIN categories c
    ON c.color_id = pc.color_id
LEFT JOIN todos t
    ON t.category_color_id = pc.color_id
WHERE p.palette_name IN ('얼씨', '네온')
GROUP BY p.palette_id, p.palette_name, pc.color_id, pc.color_order
ORDER BY p.palette_name, pc.color_order;

DROP TEMPORARY TABLE tmp_palette_color_remap;

COMMIT;


-- -- 검증
-- SELECT p.palette_id, p.palette_name, pc.color_id, pc.color_order
-- FROM palettes p
-- JOIN palette_colors pc ON pc.palette_id = p.palette_id
-- WHERE p.palette_name IN ('얼씨', '네온')
-- ORDER BY p.palette_name, pc.color_order;