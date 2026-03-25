-- ============================================================================
-- Migration 002 — Ensure discussions uses user_id & fix profile trigger
-- Apply this script against any database state.  It is idempotent.
-- ============================================================================
--
-- Changes:
--   A) Ensure discussions.user_id is the FK column to profiles
--      Reverts any prior rename of user_id → author_id so that the column
--      name matches the application code and canonical schema.
--   B) Update the profile-creation trigger to accept both 'full_name' and
--      legacy 'name' metadata keys from the Flutter app
--
-- Safe to re-run: all DDL operations are guarded with IF [NOT] EXISTS checks.
-- ============================================================================

BEGIN;

-- ============================================================================
-- A) discussions — ensure column is named user_id (revert author_id if needed)
-- ============================================================================

DO $$
BEGIN
  -- Rename author_id → user_id only if author_id exists and user_id does not
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'discussions'
      AND column_name  = 'author_id'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'discussions'
      AND column_name  = 'user_id'
  ) THEN
    ALTER TABLE public.discussions RENAME COLUMN author_id TO user_id;
  END IF;
END
$$;

-- Recreate index on the correct column
DROP INDEX IF EXISTS public.idx_discussions_author;
CREATE INDEX IF NOT EXISTS idx_discussions_user ON public.discussions(user_id);

-- ============================================================================
-- B) RLS policies for discussions — ensure they reference user_id
-- ============================================================================

-- Drop any policies that still reference author_id
DROP POLICY IF EXISTS "insert_discussions"               ON public.discussions;
DROP POLICY IF EXISTS "discussions_insert_authenticated" ON public.discussions;
DROP POLICY IF EXISTS "discussions_update_own"           ON public.discussions;
DROP POLICY IF EXISTS "discussions_delete_own"           ON public.discussions;

-- Re-create correct policies using user_id
CREATE POLICY "discussions_insert_authenticated"
  ON public.discussions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "discussions_update_own"
  ON public.discussions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "discussions_delete_own"
  ON public.discussions FOR DELETE
  USING (auth.uid() = user_id);

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
