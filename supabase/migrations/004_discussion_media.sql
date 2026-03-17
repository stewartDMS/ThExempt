-- Create discussion_media table
CREATE TABLE IF NOT EXISTS discussion_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
    media_type VARCHAR(10) NOT NULL CHECK (media_type IN ('image', 'video')),
    file_url TEXT NOT NULL,
    thumbnail_url TEXT,
    file_name TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(100),
    width INTEGER,
    height INTEGER,
    duration_seconds INTEGER,
    uploaded_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    display_order INTEGER DEFAULT 0,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE discussion_media IS 'Stores media files (images/videos) attached to discussions';
COMMENT ON COLUMN discussion_media.media_type IS 'Type of media: image or video';
COMMENT ON COLUMN discussion_media.file_url IS 'Full URL to the media file in storage';
COMMENT ON COLUMN discussion_media.thumbnail_url IS 'URL to thumbnail (primarily for videos)';
COMMENT ON COLUMN discussion_media.file_size IS 'File size in bytes';
COMMENT ON COLUMN discussion_media.duration_seconds IS 'Video duration in seconds (null for images)';
COMMENT ON COLUMN discussion_media.display_order IS 'Order for displaying media in carousel (0-based)';

-- Indexes for performance
CREATE INDEX idx_discussion_media_discussion_id ON discussion_media(discussion_id);
CREATE INDEX idx_discussion_media_uploaded_by ON discussion_media(uploaded_by);
CREATE INDEX idx_discussion_media_created_at ON discussion_media(created_at DESC);
CREATE INDEX idx_discussion_media_type ON discussion_media(media_type);

-- Enable Row Level Security
ALTER TABLE discussion_media ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Anyone can view media (public read)
CREATE POLICY "Media is viewable by everyone"
    ON discussion_media FOR SELECT
    USING (true);

-- RLS Policy: Only authenticated users can upload media
CREATE POLICY "Users can upload media to discussions"
    ON discussion_media FOR INSERT
    WITH CHECK (
        auth.uid() = uploaded_by
    );

-- RLS Policy: Users can update their own media
CREATE POLICY "Users can update their own media"
    ON discussion_media FOR UPDATE
    USING (auth.uid() = uploaded_by);

-- RLS Policy: Users can delete their own media
CREATE POLICY "Users can delete their own media"
    ON discussion_media FOR DELETE
    USING (auth.uid() = uploaded_by);

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_discussion_media_updated_at
    BEFORE UPDATE ON discussion_media
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
