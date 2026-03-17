-- Create storage bucket for discussion media
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'discussion-media',
    'discussion-media',
    true,
    104857600, -- 100MB max file size
    ARRAY[
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
        'video/mp4',
        'video/quicktime',
        'video/webm',
        'video/x-msvideo'
    ]
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Storage Policy: Anyone can view files (public bucket)
CREATE POLICY "Public Access for Discussion Media"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'discussion-media');

-- Storage Policy: Authenticated users can upload
CREATE POLICY "Authenticated users can upload discussion media"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'discussion-media'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Storage Policy: Users can update their own uploads
CREATE POLICY "Users can update their own discussion media"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'discussion-media'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Storage Policy: Users can delete their own uploads
CREATE POLICY "Users can delete their own discussion media"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'discussion-media'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
