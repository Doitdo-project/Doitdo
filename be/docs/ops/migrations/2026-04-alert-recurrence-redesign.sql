-- Alert/recurrence redesign (2026-04-25)
-- - Replace todos.period with todos.days_of_week CSV (MON,WED,FRI)
-- - Store recurring materialized instance lineage for idempotent snooze/batch insert

ALTER TABLE todos
  DROP COLUMN IF EXISTS period;

ALTER TABLE todos
  ADD COLUMN IF NOT EXISTS master_todo_id BIGINT(20) DEFAULT NULL AFTER created_at,
  ADD COLUMN IF NOT EXISTS days_of_week VARCHAR(27) DEFAULT NULL AFTER user_id;

ALTER TABLE todos
  ADD UNIQUE INDEX IF NOT EXISTS uk_todos_user_master_date (user_id, master_todo_id, start_date);
