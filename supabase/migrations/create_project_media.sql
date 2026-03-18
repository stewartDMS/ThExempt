-- Create project_media table with proper foreign key relationship
CREATE TABLE IF NOT EXISTS project_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  file_url TEXT NOT NULL,
  thumbnail_url TEXT,
  file_name TEXT,
  file_size INTEGER,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_project_media_project_id ON project_media(project_id);

-- Enable Row Level Security
ALTER TABLE project_media ENABLE ROW LEVEL SECURITY;

-- Add RLS policies
CREATE POLICY "Anyone can view project media"
  ON project_media FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can insert project media"
  ON project_media FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Project owners can delete their media"
  ON project_media FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = project_media.project_id
      AND projects.owner_id = auth.uid()
    )
  );

CREATE POLICY "Project owners can update their media"
  ON project_media FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = project_media.project_id
      AND projects.owner_id = auth.uid()
    )
  );
