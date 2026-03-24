-- ============================================================================
-- Migration 002 — Fix discussions author column & profile trigger
-- Apply this script against a database created from the schema BEFORE this
-- migration.  It is idempotent (safe to re-run).
-- ============================================================================
--
-- Changes:
--   A) Rename discussions.user_id  → discussions.author_id
--      (matches the canonical schema and RLS policies)
--   B) Update the profile-creation trigger to accept both 'full_name' and
--      legacy 'name' metadata keys from the Flutter app
--
-- If your database was already created from the up-to-date schema.sql
-- (i.e., discussions already has an author_id column), this migration is
-- a no-op due to the DO $$ ... IF NOT EXISTS ... $$ guards.
-- ============================================================================

BEGIN;

-- ============================================================================
-- A) discussions — rename user_id → author_id
-- ============================================================================

DO $$
BEGIN
  -- Only rename if the old column exists and the new one does not
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'discussions'
      AND column_name  = 'user_id'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'discussions'
      AND column_name  = 'author_id'
  ) THEN
    ALTER TABLE public.discussions RENAME COLUMN user_id TO author_id;
  END IF;
END
$$;

-- Recreate index on the (possibly renamed) column
DROP INDEX IF EXISTS public.idx_discussions_author;
CREATE INDEX IF NOT EXISTS idx_discussions_author ON public.discussions(author_id);

-- Drop legacy index that referenced the old column name
DROP INDEX IF EXISTS public.idx_discussions_user;

-- ============================================================================
-- B) RLS policies for discussions — ensure they reference author_id
-- ============================================================================

-- Drop policies that may still reference the old user_id column name
DROP POLICY IF EXISTS "insert_discussions"               ON public.discussions;
DROP POLICY IF EXISTS "discussions_insert_authenticated" ON public.discussions;
DROP POLICY IF EXISTS "discussions_update_own"           ON public.discussions;
DROP POLICY IF EXISTS "discussions_delete_own"           ON public.discussions;

-- Re-create correct policies
CREATE POLICY "discussions_insert_authenticated"
  ON public.discussions FOR INSERT
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "discussions_update_own"
  ON public.discussions FOR UPDATE
  USING (auth.uid() = author_id);

CREATE POLICY "discussions_delete_own"
  ON public.discussions FOR DELETE
  USING (auth.uid() = author_id);

-- ============================================================================
-- C) Profile creation trigger — accept both full_name and name metadata keys
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'username',
      SPLIT_PART(NEW.email, '@', 1)
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      ''
    ),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Ensure the trigger exists (idempotent)
DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION fn_handle_new_user();

COMMIT;
