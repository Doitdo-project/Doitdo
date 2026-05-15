-- palettes.display_order 컬럼 추가 + 시드 정리
-- 작성일: 2026-05-13
--
-- 적용 시점: BE 신규 배포 BEFORE 또는 동시에 실행 권장.
--   (BE 의 DataInitializer 가 부팅 시 displayOrder 를 코드 위치 기준으로 sync 하므로 사후 실행도 동작은 하지만,
--    배포 직후 잠깐 새 컬럼이 0 인 상태가 노출됨)
--
-- 본 파일이 처리하는 것:
--   1) palettes.display_order 컬럼 추가
--   2) 파스텔 → 솜사탕 rename (palette_id 유지 → 기존 Category.color_id 참조 보존)
--   3) 코드 SSOT(DataInitializer.PALETTE_SEEDS) 순서에 맞춰 display_order 백필
--
-- 본 파일이 처리하지 않는 것 (별도 작업):
--   - 얼씨 / 네온 팔레트 삭제 : categories.color_id 가 해당 색상을 참조 중인지 확인 후 결정해야 함.
--     사용 중이 아니면 별도 cleanup SQL 로 palette_colors → palettes 순으로 DELETE.

-- 1. display_order 컬럼 추가 (idempotent — 이미 있으면 NOOP)
ALTER TABLE palettes
    ADD COLUMN IF NOT EXISTS display_order INT NOT NULL DEFAULT 0;

START TRANSACTION;

-- 2. 파스텔 → 솜사탕 rename
UPDATE palettes SET palette_name = '솜사탕' WHERE palette_name = '파스텔';

-- 3. display_order 백필 — 코드 PALETTE_SEEDS 순서
UPDATE palettes SET display_order = 1 WHERE palette_name = '기본';
UPDATE palettes SET display_order = 2 WHERE palette_name = '풀잎';
UPDATE palettes SET display_order = 3 WHERE palette_name = '파도';
UPDATE palettes SET display_order = 4 WHERE palette_name = '낙엽';
UPDATE palettes SET display_order = 5 WHERE palette_name = '바위';
UPDATE palettes SET display_order = 6 WHERE palette_name = '벚꽃';
UPDATE palettes SET display_order = 7 WHERE palette_name = '솜사탕';
UPDATE palettes SET display_order = 8 WHERE palette_name = '꿈';

-- 4. 코드에서 제거된 팔레트는 뒤로 정렬 (삭제는 별도 작업)
UPDATE palettes SET display_order = 99 WHERE palette_name IN ('얼씨', '네온');

COMMIT;

-- 검증
-- SELECT palette_id, palette_name, display_order FROM palettes ORDER BY display_order, palette_id;
