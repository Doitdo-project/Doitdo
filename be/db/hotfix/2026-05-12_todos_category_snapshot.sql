-- =====================================================================
-- HOTFIX: 2026-05-12
-- 정책 변경: 카테고리 삭제 시 todo 의 카테고리 이름/색을 스냅샷으로 보존.
--
-- 기존: Todo 가 category_id 만 보유. 카테고리 삭제되면 dangling FK 가 되고
--       응답에서는 category=null 로 노출됨.
-- 변경: Todo 에 category_name / category_color_id 스냅샷 컬럼 추가.
--   1) 카테고리 rename/색 변경 시 해당 카테고리를 쓰는 활성 todo 의 스냅샷을
--      일괄 update (전파).
--   2) 카테고리 삭제 시 todo.category_id 만 NULL 로 detach 하고, 이름·색
--      스냅샷은 그대로 잔여 (정책 1).
--   3) 필터/응답은 스냅샷 이름 기반으로 매칭. 동일 이름의 활성 카테고리가
--      있으면 그 카테고리의 색이 응답 colorHex 를 override.
--
-- 코드 변경 (같은 PR):
--   - Todo 엔티티: categoryName / categoryColorId 필드 추가, 팩토리 시그니처 확장
--   - TodoRepository: bulkUpdateCategorySnapshot, detachCategoryId 추가
--   - CategoryServiceImpl.update: 변경 후 bulk update 로 propagation
--   - CategoryServiceImpl.delete: 삭제 직전 detachCategoryId 호출
--   - TodoServiceImpl: create/update 시 스냅샷 저장, 응답 시 활성 카테고리
--     맵 + 팔레트 hex 맵으로 colorHex 결정
--   - TodoSpecifications: byCategoryId 제거, byCategoryName 추가
--   - TodoListQueryRepository / RecurrenceServiceImpl: 이름 기반 매칭으로 전환
--   - TodoDetailResp / CalendarItemResp: colorHex 필드 추가
-- =====================================================================

-- 1) 스냅샷 컬럼 추가 (NULL 허용)
ALTER TABLE todos
    ADD COLUMN category_name VARCHAR(10) NULL,
    ADD COLUMN category_color_id INT NULL;

-- 2) 기존 활성 카테고리에서 이름·색 스냅샷 backfill
--    (이미 dangling 인 todo 의 category_name/color_id 는 NULL 그대로 둠)
UPDATE todos t
JOIN categories c ON c.category_id = t.category_id
SET t.category_name     = c.category_name,
    t.category_color_id = c.color_id
WHERE t.category_id IS NOT NULL;

-- 3) 이름 기반 필터를 위한 인덱스 추가
--    기존 idx_todos_list_category (category_id 기반) 는 그대로 둠 —
--    rename 일괄 update 와 detachCategoryId 의 WHERE 절 lookup 키로 활용.
CREATE INDEX idx_todos_list_category_name
    ON todos (user_id, is_deleted, category_name, start_date, todo_id);
