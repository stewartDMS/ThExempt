-- ============================================================================
-- Migration 006 — Phase 2 Movement Discovery
-- Adds collaboration_requests table and supporting indexes/policies.
-- Safe to re-run (IF NOT EXISTS throughout).
-- ============================================================================

-- ── collaboration_requests ───────────────────────────────────────────────────
-- Records requests from one user to collaborate with another or join a project.

CREATE TABLE IF NOT EXISTS collaboration_requests (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id       UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recipient_id    UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id      UUID    REFERENCES projects(id) ON DELETE CASCADE,

  -- Type: connect (user-to-user) or join_project (user-to-project)
  request_type    TEXT    NOT NULL DEFAULT 'connect'
    CHECK (request_type IN ('connect', 'join_project')),

  message         TEXT,

  status          TEXT    NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined', 'withdrawn')),

  responded_at    TIMESTAMPTZ,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One active request per sender/recipient/project combination
  UNIQUE (sender_id, recipient_id, project_id)
);

COMMENT ON TABLE  collaboration_requests IS 'Collaboration requests between users or to join a project. One pending request per sender/recipient/project.';
COMMENT ON COLUMN collaboration_requests.request_type IS 'connect = user-to-user; join_project = request to join a specific project';
COMMENT ON COLUMN collaboration_requests.status       IS 'pending | accepted | declined | withdrawn';

-- ── Indexes ──────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_collab_requests_sender    ON collaboration_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_collab_requests_recipient ON collaboration_requests(recipient_id);
CREATE INDEX IF NOT EXISTS idx_collab_requests_status    ON collaboration_requests(status);
CREATE INDEX IF NOT EXISTS idx_collab_requests_project   ON collaboration_requests(project_id) WHERE project_id IS NOT NULL;

-- ── Updated-at trigger ───────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_collaboration_requests_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_collaboration_requests_updated_at ON collaboration_requests;
CREATE TRIGGER trg_collaboration_requests_updated_at
  BEFORE UPDATE ON collaboration_requests
  FOR EACH ROW EXECUTE FUNCTION update_collaboration_requests_updated_at();

-- ── Row-Level Security ───────────────────────────────────────────────────────

ALTER TABLE collaboration_requests ENABLE ROW LEVEL SECURITY;

-- Users can view requests they sent or received
CREATE POLICY IF NOT EXISTS "collab_requests_select"
  ON collaboration_requests FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

-- Users can insert their own requests
CREATE POLICY IF NOT EXISTS "collab_requests_insert"
  ON collaboration_requests FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Sender can withdraw; recipient can accept/decline
CREATE POLICY IF NOT EXISTS "collab_requests_update"
  ON collaboration_requests FOR UPDATE
  USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

-- Sender can delete (withdraw) their own request
CREATE POLICY IF NOT EXISTS "collab_requests_delete"
  ON collaboration_requests FOR DELETE
  USING (auth.uid() = sender_id);

-- ── Ensure skill_offers and skill_requests RLS are enabled ───────────────────
-- (tables were created in the base schema but policies may not exist yet)

ALTER TABLE skill_offers  ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY IF NOT EXISTS "skill_offers_select_all"
  ON skill_offers FOR SELECT
  USING (is_active = TRUE AND deleted_at IS NULL);

CREATE POLICY IF NOT EXISTS "skill_offers_manage_own"
  ON skill_offers FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "skill_requests_select_open"
  ON skill_requests FOR SELECT
  USING (status = 'open' AND deleted_at IS NULL);

CREATE POLICY IF NOT EXISTS "skill_requests_manage_own"
  ON skill_requests FOR ALL
  USING (auth.uid() = requester_id)
  WITH CHECK (auth.uid() = requester_id);
