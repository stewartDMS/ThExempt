-- Community Discussions Table
CREATE TABLE IF NOT EXISTS discussions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',
  image_url TEXT,
  is_pinned BOOLEAN DEFAULT FALSE,
  likes_count INTEGER DEFAULT 0,
  replies_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_discussions_category ON discussions(category);
CREATE INDEX IF NOT EXISTS idx_discussions_author ON discussions(author_id);
CREATE INDEX IF NOT EXISTS idx_discussions_created ON discussions(created_at DESC);

-- Discussion Replies Table
CREATE TABLE IF NOT EXISTS discussion_replies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  discussion_id UUID REFERENCES discussions(id) ON DELETE CASCADE,
  author_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  parent_reply_id UUID REFERENCES discussion_replies(id),
  content TEXT NOT NULL,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_discussion_replies_discussion ON discussion_replies(discussion_id);
CREATE INDEX IF NOT EXISTS idx_discussion_replies_author ON discussion_replies(author_id);
CREATE INDEX IF NOT EXISTS idx_discussion_replies_parent ON discussion_replies(parent_reply_id);

-- Discussion Likes Table
CREATE TABLE IF NOT EXISTS discussion_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  discussion_id UUID REFERENCES discussions(id) ON DELETE CASCADE,
  reply_id UUID REFERENCES discussion_replies(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_discussion_likes_unique_post ON discussion_likes(discussion_id, user_id) WHERE reply_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_discussion_likes_unique_reply ON discussion_likes(reply_id, user_id) WHERE reply_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_discussion_likes_user ON discussion_likes(user_id);

-- Live Events Table
CREATE TABLE IF NOT EXISTS live_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  host_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  event_type TEXT NOT NULL,

  -- Scheduling
  scheduled_start TIMESTAMP,
  scheduled_end TIMESTAMP,
  timezone TEXT DEFAULT 'UTC',

  -- Live Session
  is_live BOOLEAN DEFAULT FALSE,
  started_at TIMESTAMP,
  ended_at TIMESTAMP,

  -- Stream Details
  stream_url TEXT,
  recording_url TEXT,
  meeting_link TEXT,

  -- Settings
  max_attendees INTEGER DEFAULT 100,
  allow_chat BOOLEAN DEFAULT TRUE,
  allow_reactions BOOLEAN DEFAULT TRUE,
  require_approval BOOLEAN DEFAULT FALSE,

  -- Stats
  viewers_count INTEGER DEFAULT 0,
  peak_viewers INTEGER DEFAULT 0,
  total_views INTEGER DEFAULT 0,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_live_events_host ON live_events(host_id);
CREATE INDEX IF NOT EXISTS idx_live_events_is_live ON live_events(is_live);
CREATE INDEX IF NOT EXISTS idx_live_events_scheduled ON live_events(scheduled_start);
CREATE INDEX IF NOT EXISTS idx_live_events_category ON live_events(category);

-- Event RSVPs Table
CREATE TABLE IF NOT EXISTS event_rsvps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID REFERENCES live_events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'attending',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_event_rsvps_event ON event_rsvps(event_id);
CREATE INDEX IF NOT EXISTS idx_event_rsvps_user ON event_rsvps(user_id);

-- Live Chat Messages Table
CREATE TABLE IF NOT EXISTS live_chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID REFERENCES live_events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_live_chat_event ON live_chat_messages(event_id);
CREATE INDEX IF NOT EXISTS idx_live_chat_created ON live_chat_messages(created_at DESC);

-- Live Reactions Table
CREATE TABLE IF NOT EXISTS live_reactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID REFERENCES live_events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  reaction_type TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_live_reactions_event ON live_reactions(event_id);
