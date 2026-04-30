-- Category name input length policy
-- App validation: CategoryCreateReq/CategoryUpdateReq name max 10 chars.

SELECT category_id, category_name, CHAR_LENGTH(category_name) AS len
FROM categories
WHERE CHAR_LENGTH(category_name) > 10;

ALTER TABLE categories
  MODIFY COLUMN category_name VARCHAR(10) NULL;
