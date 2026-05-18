-- Add user-level opt-out for tamagotchi notifications.

ALTER TABLE user_settings
  ADD COLUMN IF NOT EXISTS tamagotchi_notification_enabled TINYINT(1) NOT NULL DEFAULT 1
  AFTER evening_reminder_time;
