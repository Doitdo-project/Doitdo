-- 반복 TODO scope=from 구간 처리를 위한 그룹 식별자 추가
-- 작성일: 2026-05-15

ALTER TABLE todos
    ADD COLUMN IF NOT EXISTS recurrence_group_id BIGINT NULL AFTER master_todo_id;

UPDATE todos
SET recurrence_group_id = todo_id
WHERE type = 'RECURRING'
  AND recurrence_group_id IS NULL;

UPDATE todos child
JOIN todos master
    ON master.todo_id = child.master_todo_id
SET child.recurrence_group_id = COALESCE(master.recurrence_group_id, master.todo_id)
WHERE child.master_todo_id IS NOT NULL
  AND child.recurrence_group_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_todos_recurrence_group
    ON todos (user_id, recurrence_group_id, is_deleted, start_date, end_date);
