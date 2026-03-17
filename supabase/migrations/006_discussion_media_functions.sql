-- Function: Get discussion with all media attached
CREATE OR REPLACE FUNCTION get_discussion_with_media(discussion_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'discussion', row_to_json(d.*),
        'media', COALESCE(
            (
                SELECT json_agg(
                    json_build_object(
                        'id', dm.id,
                        'media_type', dm.media_type,
                        'file_url', dm.file_url,
                        'thumbnail_url', dm.thumbnail_url,
                        'file_name', dm.file_name,
                        'file_size', dm.file_size,
                        'mime_type', dm.mime_type,
                        'width', dm.width,
                        'height', dm.height,
                        'duration_seconds', dm.duration_seconds,
                        'uploaded_at', dm.uploaded_at,
                        'display_order', dm.display_order
                    ) ORDER BY dm.display_order, dm.created_at
                )
                FROM discussion_media dm
                WHERE dm.discussion_id = d.id
            ),
            '[]'::json
        ),
        'author', (
            SELECT json_build_object(
                'id', p.id,
                'name', p.name,
                'avatar_url', p.avatar_url
            )
            FROM profiles p
            WHERE p.id = d.author_id
        )
    ) INTO result
    FROM discussions d
    WHERE d.id = discussion_uuid;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_discussion_with_media IS 'Returns discussion with all attached media and author info as JSON';

-- Function: Validate media upload before insert
CREATE OR REPLACE FUNCTION validate_media_upload(
    p_discussion_id UUID,
    p_media_type VARCHAR,
    p_file_size BIGINT
)
RETURNS BOOLEAN AS $$
DECLARE
    media_count INTEGER;
    max_media_per_discussion INTEGER := 5;
    max_image_size BIGINT := 10485760;  -- 10MB
    max_video_size BIGINT := 104857600; -- 100MB
BEGIN
    IF NOT EXISTS (SELECT 1 FROM discussions WHERE id = p_discussion_id) THEN
        RAISE EXCEPTION 'Discussion not found';
    END IF;

    SELECT COUNT(*) INTO media_count
    FROM discussion_media
    WHERE discussion_id = p_discussion_id;

    IF media_count >= max_media_per_discussion THEN
        RAISE EXCEPTION 'Maximum % media files allowed per discussion', max_media_per_discussion;
    END IF;

    IF p_media_type = 'image' AND p_file_size > max_image_size THEN
        RAISE EXCEPTION 'Image size must be less than 10MB';
    END IF;

    IF p_media_type = 'video' AND p_file_size > max_video_size THEN
        RAISE EXCEPTION 'Video size must be less than 100MB';
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_media_upload IS 'Validates media upload constraints (max 5 files, size limits)';

-- Function: Get media count for a discussion
CREATE OR REPLACE FUNCTION get_media_count(discussion_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    count INTEGER;
BEGIN
    SELECT COUNT(*) INTO count
    FROM discussion_media
    WHERE discussion_id = discussion_uuid;
    RETURN count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_media_count IS 'Returns count of media files attached to a discussion';

-- Function: Reorder media display order
CREATE OR REPLACE FUNCTION reorder_media(
    media_ids UUID[],
    discussion_uuid UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    media_id UUID;
    idx INTEGER := 0;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM discussions d
        JOIN discussion_media dm ON d.id = dm.discussion_id
        WHERE d.id = discussion_uuid
        AND (d.author_id = auth.uid() OR dm.uploaded_by = auth.uid())
    ) THEN
        RAISE EXCEPTION 'Unauthorized to reorder media';
    END IF;

    FOREACH media_id IN ARRAY media_ids
    LOOP
        UPDATE discussion_media
        SET display_order = idx
        WHERE id = media_id
        AND discussion_id = discussion_uuid;
        idx := idx + 1;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION reorder_media IS 'Reorder media display order for a discussion';
