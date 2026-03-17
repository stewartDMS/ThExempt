-- Add media_count column to discussions table
ALTER TABLE discussions
ADD COLUMN IF NOT EXISTS media_count INTEGER DEFAULT 0;

COMMENT ON COLUMN discussions.media_count IS 'Cached count of media files attached to this discussion';

-- Function to automatically update media count
CREATE OR REPLACE FUNCTION update_discussion_media_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE discussions
        SET media_count = media_count + 1,
            updated_at = NOW()
        WHERE id = NEW.discussion_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE discussions
        SET media_count = GREATEST(media_count - 1, 0),
            updated_at = NOW()
        WHERE id = OLD.discussion_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update media count on insert/delete
CREATE TRIGGER update_discussion_media_count_trigger
    AFTER INSERT OR DELETE ON discussion_media
    FOR EACH ROW
    EXECUTE FUNCTION update_discussion_media_count();

-- Backfill existing discussions (set correct media_count)
UPDATE discussions d
SET media_count = (
    SELECT COUNT(*)
    FROM discussion_media dm
    WHERE dm.discussion_id = d.id
);
