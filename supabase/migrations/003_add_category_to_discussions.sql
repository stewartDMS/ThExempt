-- ============================================================================
-- Migration 003 — Add optional 'category' column to public.discussions
-- ============================================================================
--
-- Changes:
--   A) Add discussions.category (TEXT, nullable) if it does not already exist.
--      Nullable so that any existing rows are unaffected by the migration.
--      Application code should supply a value on every new insert; existing
--      rows can be back-filled manually if required.
--
--   B) Add an index on discussions.category to support category-filter queries
--      efficiently.
--
-- Safe to re-run: all DDL operations are guarded with IF [NOT] EXISTS checks.
-- ============================================================================

BEGIN;

-- ============================================================================
-- A) discussions — add category column (nullable text) if absent
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'discussions'
      AND column_name  = 'category'
  ) THEN
    ALTER TABLE public.discussions ADD COLUMN category TEXT NULL;
  END IF;
END
$$;

-- ============================================================================
-- B) Index on discussions.category for fast category-based filtering
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_discussions_category ON public.discussions(category);

-- ============================================================================
-- C) Column comment
-- ============================================================================

COMMENT ON COLUMN public.discussions.category IS
  'Optional thread category. Values: world_problems | ideas | learning | '
  'live_events | networking | feedback | general | climate_crisis | '
  'economic_inequality | healthcare_access | education_reform | '
  'housing_justice | criminal_justice | immigration_justice | '
  'mental_health_crisis. Nullable to allow posts without a category.';

-- ============================================================================
-- D) Smoke-test: insert a discussion row without category and one with category,
--    then clean up.  Only runs during an explicit test pass (e.g. in Supabase
--    SQL Editor); comment out the ROLLBACK to keep the rows.
-- ============================================================================
--
-- -- Requires a valid profile UUID in place of '<your-user-uuid>'.
-- DO $$
-- DECLARE
--   test_user UUID := '<your-user-uuid>';
--   id_without UUID;
--   id_with    UUID;
-- BEGIN
--   -- Insert without category (category IS NULL)
--   INSERT INTO public.discussions (user_id, title, content)
--   VALUES (test_user, 'Test: no category', 'Smoke-test row — no category set.')
--   RETURNING id INTO id_without;
--
--   -- Insert with category
--   INSERT INTO public.discussions (user_id, title, content, category)
--   VALUES (test_user, 'Test: with category', 'Smoke-test row — category set.', 'general')
--   RETURNING id INTO id_with;
--
--   RAISE NOTICE 'Inserted id_without=%, id_with=%', id_without, id_with;
--
--   -- Clean up
--   DELETE FROM public.discussions WHERE id IN (id_without, id_with);
-- END
-- $$;

COMMIT;
