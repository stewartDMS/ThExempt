-- ============================================================
-- ThExempt Platform - Consolidated MVP Schema for Supabase
-- ============================================================
-- Single source of truth for the ThExempt database schema.
-- Apply this file in the Supabase SQL Editor to set up the
-- complete database. See supabase/MIGRATION_GUIDE.md for
-- step-by-step instructions.
-- ============================================================

-- ============================================================
-- UTILITY FUNCTION: auto-update updated_at column
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- CORE TABLE: profiles
-- Extends Supabase auth.users with public profile data.
-- ============================================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  website_url TEXT,
  location TEXT,

  -- Stats (cached counts, updated by triggers)
  contributions_count INTEGER DEFAULT 0,
  projects_count INTEGER DEFAULT 0,
  followers_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE profiles IS 'Public profile data extending Supabase auth.users';
COMMENT ON COLUMN profiles.username IS 'Unique handle for the user (e.g. @alice)';
COMMENT ON COLUMN profiles.contributions_count IS 'Cached count of approved contributions';
COMMENT ON COLUMN profiles.followers_count IS 'Cached count of followers';

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON profiles(created_at DESC);

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- CORE TABLE: projects
-- Social impact projects created by users.
-- ============================================================

CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Content
  title TEXT NOT NULL,
  tagline TEXT,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',

  -- Status
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),

  -- Engagement (cached counts)
  views_count INTEGER DEFAULT 0,
  likes_count INTEGER DEFAULT 0,
  followers_count INTEGER DEFAULT 0,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ
);

COMMENT ON TABLE projects IS 'Social impact projects created by community members';
COMMENT ON COLUMN projects.status IS 'Lifecycle stage: draft → active → completed/cancelled';
COMMENT ON COLUMN projects.tags IS 'Array of topic tags for discoverability';

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Projects are viewable by everyone"
  ON projects FOR SELECT
  USING (true);

CREATE POLICY "Users can create projects"
  ON projects FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own projects"
  ON projects FOR UPDATE
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own projects"
  ON projects FOR DELETE
  USING (auth.uid() = owner_id);

CREATE INDEX IF NOT EXISTS idx_projects_owner ON projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);
CREATE INDEX IF NOT EXISTS idx_projects_category ON projects(category);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at DESC);

CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- CORE TABLE: contributions
-- User contributions to projects (tracks work & impact).
-- ============================================================

CREATE TABLE IF NOT EXISTS contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contributor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,

  -- Content
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  impact_description TEXT,

  -- Classification
  contribution_type TEXT CHECK (contribution_type IN ('code', 'design', 'content', 'funding', 'advocacy', 'other')),
  tags TEXT[] DEFAULT '{}',

  -- Hours
  hours_worked NUMERIC(5,1),

  -- Verification
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
  verified_at TIMESTAMPTZ,
  verification_proof TEXT,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE contributions IS 'Tracks user contributions to social impact projects';
COMMENT ON COLUMN contributions.contribution_type IS 'Category: code, design, content, funding, advocacy, other';
COMMENT ON COLUMN contributions.status IS 'Verification state: pending → verified/rejected';
COMMENT ON COLUMN contributions.verification_proof IS 'URL or description of proof for verification';
COMMENT ON COLUMN contributions.impact_description IS 'How this contribution created social impact';

ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Contributions are viewable by everyone"
  ON contributions FOR SELECT
  USING (true);

CREATE POLICY "Users can create contributions"
  ON contributions FOR INSERT
  WITH CHECK (auth.uid() = contributor_id);

CREATE POLICY "Users can update own contributions"
  ON contributions FOR UPDATE
  USING (auth.uid() = contributor_id);

CREATE POLICY "Users can delete own contributions"
  ON contributions FOR DELETE
  USING (auth.uid() = contributor_id);

CREATE INDEX IF NOT EXISTS idx_contributions_contributor ON contributions(contributor_id);
CREATE INDEX IF NOT EXISTS idx_contributions_project ON contributions(project_id);
CREATE INDEX IF NOT EXISTS idx_contributions_status ON contributions(status);
CREATE INDEX IF NOT EXISTS idx_contributions_type ON contributions(contribution_type);
CREATE INDEX IF NOT EXISTS idx_contributions_created_at ON contributions(created_at DESC);

CREATE TRIGGER update_contributions_updated_at
  BEFORE UPDATE ON contributions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- CORE TABLE: discussions
-- Community discussion threads.
-- ============================================================

CREATE TABLE IF NOT EXISTS discussions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Content
  category TEXT NOT NULL CHECK (category IN ('world_problems', 'ideas', 'learning', 'networking', 'feedback', 'general')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',

  -- Moderation
  is_pinned BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,

  -- Engagement (cached counts)
  likes_count INTEGER DEFAULT 0,
  replies_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  media_count INTEGER DEFAULT 0,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE discussions IS 'Community discussion threads organized by category';
COMMENT ON COLUMN discussions.category IS 'Topic category for the discussion';
COMMENT ON COLUMN discussions.is_pinned IS 'Pinned discussions appear at the top of their category';
COMMENT ON COLUMN discussions.media_count IS 'Cached count of attached media files';

ALTER TABLE discussions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Discussions are viewable by everyone"
  ON discussions FOR SELECT
  USING (true);

CREATE POLICY "Users can create discussions"
  ON discussions FOR INSERT
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own discussions"
  ON discussions FOR UPDATE
  USING (auth.uid() = author_id);

CREATE POLICY "Users can delete own discussions"
  ON discussions FOR DELETE
  USING (auth.uid() = author_id);

CREATE INDEX IF NOT EXISTS idx_discussions_author ON discussions(author_id);
CREATE INDEX IF NOT EXISTS idx_discussions_category ON discussions(category);
CREATE INDEX IF NOT EXISTS idx_discussions_created_at ON discussions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_discussions_trending ON discussions(likes_count DESC, replies_count DESC);

CREATE TRIGGER update_discussions_updated_at
  BEFORE UPDATE ON discussions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- CORE TABLE: discussion_replies
-- Threaded replies within discussions.
-- ============================================================

CREATE TABLE IF NOT EXISTS discussion_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  parent_reply_id UUID REFERENCES discussion_replies(id) ON DELETE CASCADE,

  -- Content
  content TEXT NOT NULL,

  -- Engagement (cached counts)
  likes_count INTEGER DEFAULT 0,

  -- Moderation
  is_solution BOOLEAN DEFAULT FALSE,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE discussion_replies IS 'Threaded replies within community discussions';
COMMENT ON COLUMN discussion_replies.parent_reply_id IS 'NULL = top-level reply; non-NULL = nested reply';
COMMENT ON COLUMN discussion_replies.is_solution IS 'Marked as the accepted answer by the discussion author';

ALTER TABLE discussion_replies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Replies are viewable by everyone"
  ON discussion_replies FOR SELECT
  USING (true);

CREATE POLICY "Users can create replies"
  ON discussion_replies FOR INSERT
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own replies"
  ON discussion_replies FOR UPDATE
  USING (auth.uid() = author_id);

CREATE POLICY "Users can delete own replies"
  ON discussion_replies FOR DELETE
  USING (auth.uid() = author_id);

CREATE INDEX IF NOT EXISTS idx_replies_discussion ON discussion_replies(discussion_id);
CREATE INDEX IF NOT EXISTS idx_replies_author ON discussion_replies(author_id);
CREATE INDEX IF NOT EXISTS idx_replies_parent ON discussion_replies(parent_reply_id);

CREATE TRIGGER update_discussion_replies_updated_at
  BEFORE UPDATE ON discussion_replies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- CORE TABLE: discussion_likes
-- Like system for discussions and replies.
-- ============================================================

CREATE TABLE IF NOT EXISTS discussion_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID REFERENCES discussions(id) ON DELETE CASCADE,
  reply_id UUID REFERENCES discussion_replies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Exactly one of discussion_id or reply_id must be set
  CHECK (
    (discussion_id IS NOT NULL AND reply_id IS NULL) OR
    (discussion_id IS NULL AND reply_id IS NOT NULL)
  ),

  -- One like per user per item
  UNIQUE NULLS NOT DISTINCT (user_id, discussion_id, reply_id)
);

COMMENT ON TABLE discussion_likes IS 'Likes on discussions and discussion replies';
COMMENT ON COLUMN discussion_likes.discussion_id IS 'Set when liking a discussion (reply_id must be NULL)';
COMMENT ON COLUMN discussion_likes.reply_id IS 'Set when liking a reply (discussion_id must be NULL)';

ALTER TABLE discussion_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Likes are viewable by everyone"
  ON discussion_likes FOR SELECT
  USING (true);

CREATE POLICY "Users can like items"
  ON discussion_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike items"
  ON discussion_likes FOR DELETE
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_discussion_likes_user ON discussion_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_discussion_likes_discussion ON discussion_likes(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_likes_reply ON discussion_likes(reply_id);

-- ============================================================
-- CORE TABLE: discussion_media
-- Images and videos attached to discussions.
-- ============================================================

CREATE TABLE IF NOT EXISTS discussion_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- File info
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  file_url TEXT NOT NULL,
  thumbnail_url TEXT,
  file_name TEXT,
  file_size BIGINT,
  mime_type TEXT,
  width INTEGER,
  height INTEGER,
  duration_seconds INTEGER,
  display_order INTEGER DEFAULT 0,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE discussion_media IS 'Images and videos attached to discussions';
COMMENT ON COLUMN discussion_media.media_type IS 'Type: image or video';
COMMENT ON COLUMN discussion_media.file_url IS 'Full URL to the media file in Supabase Storage';
COMMENT ON COLUMN discussion_media.file_size IS 'File size in bytes';
COMMENT ON COLUMN discussion_media.display_order IS 'Display order in carousel (0-based)';

ALTER TABLE discussion_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Media is viewable by everyone"
  ON discussion_media FOR SELECT
  USING (true);

CREATE POLICY "Users can upload media to discussions"
  ON discussion_media FOR INSERT
  WITH CHECK (auth.uid() = uploaded_by);

CREATE POLICY "Users can update their own media"
  ON discussion_media FOR UPDATE
  USING (auth.uid() = uploaded_by);

CREATE POLICY "Users can delete their own media"
  ON discussion_media FOR DELETE
  USING (auth.uid() = uploaded_by);

CREATE INDEX IF NOT EXISTS idx_discussion_media_discussion ON discussion_media(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_media_uploaded_by ON discussion_media(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_discussion_media_created_at ON discussion_media(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_discussion_media_type ON discussion_media(media_type);

CREATE TRIGGER update_discussion_media_updated_at
  BEFORE UPDATE ON discussion_media
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SUPPORTING TABLE: notifications
-- User notification inbox.
-- ============================================================

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Content
  type TEXT NOT NULL CHECK (type IN ('like', 'reply', 'follow', 'mention', 'project_update', 'contribution_verified', 'system')),
  title TEXT NOT NULL,
  message TEXT,

  -- Reference to the source object
  reference_type TEXT CHECK (reference_type IN ('discussion', 'reply', 'project', 'contribution', 'profile')),
  reference_id UUID,

  -- Status
  is_read BOOLEAN DEFAULT FALSE,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE notifications IS 'User notification inbox for platform activity';
COMMENT ON COLUMN notifications.type IS 'Category of notification event';
COMMENT ON COLUMN notifications.reference_id IS 'UUID of the related object (polymorphic)';
COMMENT ON COLUMN notifications.is_read IS 'Whether the user has read this notification';

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- ============================================================
-- SUPPORTING TABLE: follows
-- User follow relationships.
-- ============================================================

CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Cannot follow yourself
  CHECK (follower_id != following_id),

  -- Only one follow per pair
  UNIQUE (follower_id, following_id)
);

COMMENT ON TABLE follows IS 'User follow relationships (follower follows following)';
COMMENT ON COLUMN follows.follower_id IS 'The user who is following';
COMMENT ON COLUMN follows.following_id IS 'The user being followed';

ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Follows are viewable by everyone"
  ON follows FOR SELECT
  USING (true);

CREATE POLICY "Users can follow others"
  ON follows FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow others"
  ON follows FOR DELETE
  USING (auth.uid() = follower_id);

CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);

-- ============================================================
-- SUPPORTING TABLE: project_updates
-- Project announcements and progress updates.
-- ============================================================

CREATE TABLE IF NOT EXISTS project_updates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Content
  title TEXT NOT NULL,
  content TEXT NOT NULL,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE project_updates IS 'Announcements and progress updates for projects';

ALTER TABLE project_updates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Project updates are viewable by everyone"
  ON project_updates FOR SELECT
  USING (true);

CREATE POLICY "Project owners can create updates"
  ON project_updates FOR INSERT
  WITH CHECK (
    auth.uid() = author_id AND
    auth.uid() IN (SELECT owner_id FROM projects WHERE id = project_id)
  );

CREATE POLICY "Project owners can update their updates"
  ON project_updates FOR UPDATE
  USING (auth.uid() = author_id);

CREATE POLICY "Project owners can delete their updates"
  ON project_updates FOR DELETE
  USING (auth.uid() = author_id);

CREATE INDEX IF NOT EXISTS idx_project_updates_project ON project_updates(project_id);
CREATE INDEX IF NOT EXISTS idx_project_updates_author ON project_updates(author_id);
CREATE INDEX IF NOT EXISTS idx_project_updates_created_at ON project_updates(created_at DESC);

CREATE TRIGGER update_project_updates_updated_at
  BEFORE UPDATE ON project_updates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SUPPORTING TABLE: comments
-- Comments on projects and contributions.
-- ============================================================

CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

  -- Polymorphic reference: exactly one of these must be set
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  contribution_id UUID REFERENCES contributions(id) ON DELETE CASCADE,

  -- Content
  content TEXT NOT NULL,

  -- Engagement (cached counts)
  likes_count INTEGER DEFAULT 0,

  -- Meta
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CHECK (
    (project_id IS NOT NULL AND contribution_id IS NULL) OR
    (project_id IS NULL AND contribution_id IS NOT NULL)
  )
);

COMMENT ON TABLE comments IS 'Comments on projects and contributions';
COMMENT ON COLUMN comments.project_id IS 'Set when commenting on a project (contribution_id must be NULL)';
COMMENT ON COLUMN comments.contribution_id IS 'Set when commenting on a contribution (project_id must be NULL)';

ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments are viewable by everyone"
  ON comments FOR SELECT
  USING (true);

CREATE POLICY "Users can create comments"
  ON comments FOR INSERT
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own comments"
  ON comments FOR UPDATE
  USING (auth.uid() = author_id);

CREATE POLICY "Users can delete own comments"
  ON comments FOR DELETE
  USING (auth.uid() = author_id);

CREATE INDEX IF NOT EXISTS idx_comments_author ON comments(author_id);
CREATE INDEX IF NOT EXISTS idx_comments_project ON comments(project_id);
CREATE INDEX IF NOT EXISTS idx_comments_contribution ON comments(contribution_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at DESC);

CREATE TRIGGER update_comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- TRIGGERS: Maintain cached engagement counts
-- ============================================================

-- Auto-increment/decrement discussion likes_count
CREATE OR REPLACE FUNCTION handle_discussion_like()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF NEW.discussion_id IS NOT NULL THEN
      UPDATE discussions SET likes_count = likes_count + 1 WHERE id = NEW.discussion_id;
    ELSIF NEW.reply_id IS NOT NULL THEN
      UPDATE discussion_replies SET likes_count = likes_count + 1 WHERE id = NEW.reply_id;
    END IF;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    IF OLD.discussion_id IS NOT NULL THEN
      UPDATE discussions SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.discussion_id;
    ELSIF OLD.reply_id IS NOT NULL THEN
      UPDATE discussion_replies SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.reply_id;
    END IF;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_discussion_like_change
  AFTER INSERT OR DELETE ON discussion_likes
  FOR EACH ROW
  EXECUTE FUNCTION handle_discussion_like();

-- Auto-increment/decrement discussion replies_count
CREATE OR REPLACE FUNCTION handle_discussion_reply()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE discussions SET replies_count = replies_count + 1 WHERE id = NEW.discussion_id;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE discussions SET replies_count = GREATEST(replies_count - 1, 0) WHERE id = OLD.discussion_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_discussion_reply_change
  AFTER INSERT OR DELETE ON discussion_replies
  FOR EACH ROW
  EXECUTE FUNCTION handle_discussion_reply();

-- Auto-increment/decrement discussion media_count
CREATE OR REPLACE FUNCTION handle_discussion_media_count()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE discussions SET media_count = media_count + 1 WHERE id = NEW.discussion_id;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE discussions SET media_count = GREATEST(media_count - 1, 0) WHERE id = OLD.discussion_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_discussion_media_change
  AFTER INSERT OR DELETE ON discussion_media
  FOR EACH ROW
  EXECUTE FUNCTION handle_discussion_media_count();

-- Auto-update profiles followers_count and following_count
CREATE OR REPLACE FUNCTION handle_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE profiles SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
    UPDATE profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE profiles SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = OLD.following_id;
    UPDATE profiles SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_follow_change
  AFTER INSERT OR DELETE ON follows
  FOR EACH ROW
  EXECUTE FUNCTION handle_follow_counts();

-- ============================================================
-- VIEWS
-- ============================================================

-- Trending discussions (past 7 days, ordered by engagement)
CREATE OR REPLACE VIEW trending_discussions AS
SELECT
  d.id,
  d.title,
  d.category,
  d.author_id,
  d.likes_count,
  d.replies_count,
  d.views_count,
  d.media_count,
  (d.likes_count * 2 + d.replies_count * 3 + d.views_count) AS trending_score,
  d.created_at
FROM discussions d
WHERE
  d.is_archived = FALSE
  AND d.created_at > NOW() - INTERVAL '7 days'
ORDER BY trending_score DESC;

COMMENT ON VIEW trending_discussions IS 'Top discussions from the past 7 days, ranked by engagement';
