-- View: Discussions with media aggregated
CREATE OR REPLACE VIEW discussions_with_media AS
SELECT
    d.id,
    d.title,
    d.content,
    d.category,
    d.tags,
    d.author_id,
    d.created_at,
    d.updated_at,
    d.views_count,
    d.likes_count,
    d.replies_count,
    d.media_count,

    -- Author info
    p.name AS author_name,
    p.avatar_url AS author_avatar,

    -- Media aggregated as JSON array
    COALESCE(
        json_agg(
            json_build_object(
                'id', dm.id,
                'media_type', dm.media_type,
                'file_url', dm.file_url,
                'thumbnail_url', dm.thumbnail_url,
                'file_name', dm.file_name,
                'file_size', dm.file_size,
                'width', dm.width,
                'height', dm.height,
                'duration_seconds', dm.duration_seconds,
                'display_order', dm.display_order
            ) ORDER BY dm.display_order, dm.created_at
        ) FILTER (WHERE dm.id IS NOT NULL),
        '[]'::json
    ) AS media
FROM discussions d
LEFT JOIN profiles p ON d.author_id = p.id
LEFT JOIN discussion_media dm ON d.id = dm.discussion_id
GROUP BY d.id, p.id, p.name, p.avatar_url;

COMMENT ON VIEW discussions_with_media IS 'Discussions with media and author info aggregated for easy querying';

-- View: User media uploads
CREATE OR REPLACE VIEW user_media_uploads AS
SELECT
    dm.id,
    dm.discussion_id,
    dm.media_type,
    dm.file_url,
    dm.thumbnail_url,
    dm.file_name,
    dm.file_size,
    dm.uploaded_at,
    d.title AS discussion_title,
    p.name AS uploader_name,
    p.avatar_url AS uploader_avatar
FROM discussion_media dm
JOIN discussions d ON dm.discussion_id = d.id
JOIN profiles p ON dm.uploaded_by = p.id
ORDER BY dm.uploaded_at DESC;

COMMENT ON VIEW user_media_uploads IS 'All media uploads with discussion and uploader info';

-- View: Media statistics per discussion
CREATE OR REPLACE VIEW discussion_media_stats AS
SELECT
    d.id AS discussion_id,
    d.title,
    COUNT(dm.id) AS total_media,
    COUNT(dm.id) FILTER (WHERE dm.media_type = 'image') AS image_count,
    COUNT(dm.id) FILTER (WHERE dm.media_type = 'video') AS video_count,
    COALESCE(SUM(dm.file_size), 0) AS total_size_bytes,
    ROUND(COALESCE(SUM(dm.file_size), 0) / 1024.0 / 1024.0, 2) AS total_size_mb
FROM discussions d
LEFT JOIN discussion_media dm ON d.id = dm.discussion_id
GROUP BY d.id, d.title;

COMMENT ON VIEW discussion_media_stats IS 'Media statistics per discussion (counts, sizes)';
