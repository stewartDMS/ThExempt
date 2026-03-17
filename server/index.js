const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const supabase = require('./supabase');

const app = express();
const PORT = process.env.PORT || 5000;

// Rate limiting for auth routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 requests per windowMs
  message: 'Too many authentication attempts, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

// General API rate limiting
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
});

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '60mb' }));
app.use(bodyParser.urlencoded({ limit: '60mb', extended: true }));
app.use('/api/', apiLimiter);
app.use(express.static(path.join(__dirname, '../client/public')));

// Authentication middleware
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Authentication required - No token provided' });
  }

  try {
    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    if (error || !user) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    
    req.user = { id: user.id, email: user.email };
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
};

// Auth routes
app.post('/api/auth/signup', authLimiter, async (req, res) => {
  const { email, password, name } = req.body;

  if (!email || !password || !name) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    // Sign up with Supabase Auth
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          name: name
        }
      }
    });

    if (error) {
      if (error.message.includes('already registered')) {
        return res.status(400).json({ error: 'Email already exists' });
      }
      return res.status(400).json({ error: error.message });
    }

    if (!data.user || !data.session) {
      return res.status(500).json({ error: 'Failed to create user' });
    }

    // Get or create profile
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', data.user.id)
      .single();

    res.json({
      token: data.session.access_token,
      user: {
        id: data.user.id,
        email: data.user.email,
        name: profile?.name || name,
        reputation_points: profile?.reputation_points || 0,
        badges: profile?.badges || []
      }
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/auth/login', authLimiter, async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    // Sign in with Supabase Auth
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    if (!data.user || !data.session) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Fetch user profile
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', data.user.id)
      .single();

    res.json({
      token: data.session.access_token,
      user: {
        id: data.user.id,
        email: data.user.email,
        name: profile?.name || data.user.user_metadata?.name || '',
        role: profile?.role || 'member',
        reputation_points: profile?.reputation_points || 0,
        badges: profile?.badges || []
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// User routes
app.get('/api/users/me', authenticateToken, async (req, res) => {
  try {
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('id, email, name, role, reputation_points, badges')
      .eq('id', req.user.id)
      .single();

    if (error || !profile) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(profile);
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/api/users/:id/skills', async (req, res) => {
  try {
    const { data: skills, error } = await supabase
      .from('user_skills')
      .select('skill, proficiency')
      .eq('user_id', req.params.id);

    if (error) {
      return res.status(500).json({ error: 'Failed to fetch skills' });
    }

    res.json(skills || []);
  } catch (error) {
    console.error('Get skills error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/users/skills', authenticateToken, async (req, res) => {
  const { skill, proficiency } = req.body;
  
  try {
    const { data, error } = await supabase
      .from('user_skills')
      .insert({
        user_id: req.user.id,
        skill,
        proficiency: proficiency || 1
      })
      .select()
      .single();

    if (error) {
      return res.status(500).json({ error: 'Failed to add skill' });
    }

    res.json(data);
  } catch (error) {
    console.error('Add skill error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Search users (must be before /api/users/:id to avoid route conflict)
app.get('/api/users/search', async (req, res) => {
  const { query = '', limit = 10 } = req.query;

  try {
    // Sanitize query to prevent SQL injection - escape special characters
    const sanitizedQuery = query.replace(/[\\%_]/g, '\\$&');
    
    const { data: users, error } = await supabase
      .from('profiles')
      .select('id, name, username, bio, avatar_url, location, industry, reputation_points, badges')
      .or(`name.ilike.%${sanitizedQuery}%,username.ilike.%${sanitizedQuery}%,bio.ilike.%${sanitizedQuery}%,industry.ilike.%${sanitizedQuery}%`)
      .limit(limit);

    if (error) {
      return res.status(500).json({ error: 'Search failed' });
    }

    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get user profile by username (must be before /api/users/:id)
app.get('/api/users/username/:username', async (req, res) => {
  try {
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('id, name, username, bio, avatar_url, cover_image_url, location, github_url, linkedin_url, website_url, availability_status, profile_views, industry, skills, role, reputation_points, badges, primary_expertise, expertise_level, created_at')
      .eq('username', req.params.username)
      .single();

    if (error || !profile) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(profile);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get user profile by ID
app.get('/api/users/:id', async (req, res) => {
  try {
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('id, name, username, bio, avatar_url, cover_image_url, location, github_url, linkedin_url, website_url, availability_status, profile_views, industry, skills, role, reputation_points, badges, primary_expertise, expertise_level, created_at')
      .eq('id', req.params.id)
      .single();

    if (error || !profile) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Increment profile views (non-blocking)
    supabase
      .from('profiles')
      .update({ profile_views: (profile.profile_views || 0) + 1 })
      .eq('id', req.params.id)
      .then(() => {}).catch(() => {});

    res.json(profile);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update user profile
app.put('/api/users/me', authenticateToken, async (req, res) => {
  const { name, username, bio, location, industry, skills, avatar_url, cover_image_url, github_url, linkedin_url, website_url, availability_status } = req.body;

  try {
    const { data, error } = await supabase
      .from('profiles')
      .update({
        name,
        username,
        bio,
        location,
        industry,
        skills,
        avatar_url,
        cover_image_url,
        github_url,
        linkedin_url,
        website_url,
        availability_status,
        updated_at: new Date().toISOString()
      })
      .eq('id', req.user.id)
      .select()
      .single();

    if (error) {
      return res.status(500).json({ error: 'Failed to update profile' });
    }

    res.json(data);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get user stats
app.get('/api/users/:id/stats', async (req, res) => {
  try {
    const userId = req.params.id;

    const [projectsResult, likesResult, profileResult] = await Promise.all([
      supabase
        .from('projects')
        .select('id', { count: 'exact' })
        .eq('owner_id', userId),
      supabase
        .from('contributions')
        .select('points')
        .eq('user_id', userId),
      supabase
        .from('profiles')
        .select('profile_views')
        .eq('id', userId)
        .single()
    ]);

    const totalProjects = projectsResult.count || 0;
    const totalLikes = (likesResult.data || []).reduce((sum, c) => sum + (c.points || 0), 0);
    const profileViews = profileResult.data?.profile_views || 0;

    res.json({
      total_projects: totalProjects,
      total_likes: totalLikes,
      profile_views: profileViews
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get user's projects
app.get('/api/users/:id/projects', async (req, res) => {
  try {
    const { data: projects, error } = await supabase
      .from('projects')
      .select('*')
      .eq('owner_id', req.params.id)
      .order('created_at', { ascending: false });

    if (error) {
      return res.status(500).json({ error: 'Failed to fetch user projects' });
    }

    res.json(projects || []);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Upload avatar
app.post('/api/users/avatar', authenticateToken, async (req, res) => {
  const { base64Image, fileName } = req.body;

  try {
    // Extract content type from base64 data
    const matches = base64Image.match(/^data:image\/(\w+);base64,/);
    const imageType = matches ? matches[1] : 'png';
    const contentType = `image/${imageType}`;
    
    // Convert base64 to buffer
    const base64Data = base64Image.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');

    // Upload to Supabase Storage
    const filePath = `avatars/${req.user.id}/${fileName}`;
    const { data, error } = await supabase.storage
      .from('user-uploads')
      .upload(filePath, buffer, {
        contentType: contentType,
        upsert: true
      });

    if (error) {
      return res.status(500).json({ error: 'Upload failed' });
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from('user-uploads')
      .getPublicUrl(filePath);

    // Update profile with avatar URL
    await supabase
      .from('profiles')
      .update({ avatar_url: urlData.publicUrl })
      .eq('id', req.user.id);

    res.json({ avatar_url: urlData.publicUrl });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Project routes
app.get('/api/projects', async (req, res) => {
  try {
    const { data: projects, error } = await supabase
      .from('projects')
      .select(`
        *,
        profiles!projects_owner_id_fkey(name, avatar_url)
      `)
      .eq('status', 'open')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Get projects error:', error);
      return res.status(500).json({ error: 'Failed to fetch projects' });
    }

    // Format response to match expected structure
    const formattedProjects = projects.map(p => ({
      ...p,
      owner_name: p.profiles?.name || 'Unknown',
      owner_avatar_url: p.profiles?.avatar_url || null
    }));

    res.json(formattedProjects);
  } catch (error) {
    console.error('Get projects error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/api/projects/:id', async (req, res) => {
  try {
    const { data: project, error } = await supabase
      .from('projects')
      .select(`
        *,
        profiles!projects_owner_id_fkey(name, avatar_url)
      `)
      .eq('id', req.params.id)
      .single();

    if (error || !project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    // Format response to match expected structure
    res.json({
      ...project,
      owner_name: project.profiles?.name || 'Unknown',
      owner_avatar_url: project.profiles?.avatar_url || null
    });
  } catch (error) {
    console.error('Get project error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/projects', authenticateToken, async (req, res) => {
  const { title, description, required_skills } = req.body;

  if (!title || !description) {
    return res.status(400).json({ error: 'Title and description are required' });
  }

  try {
    const { data, error } = await supabase
      .from('projects')
      .insert({
        title,
        description,
        owner_id: req.user.id,
        required_skills: required_skills || [],
        status: 'open'
      })
      .select()
      .single();

    if (error) {
      console.error('Create project error:', error);
      return res.status(500).json({ error: 'Failed to create project' });
    }

    res.json(data);
  } catch (error) {
    console.error('Create project error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Video attachment endpoint for projects
app.post('/api/projects/:id/video', authenticateToken, async (req, res) => {
  const { base64Video, fileName, thumbnailBase64 } = req.body;
  const projectId = req.params.id;

  try {
    const { data: projectData, error: fetchErr } = await supabase
      .from('projects')
      .select('owner_id, video_url')
      .eq('id', projectId)
      .single();

    if (fetchErr || !projectData) {
      return res.status(404).json({ error: 'Project not found' });
    }

    if (projectData.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const mimeTypeMatch = base64Video.match(/^data:(.+);base64,/);
    if (!mimeTypeMatch) {
      return res.status(400).json({ error: 'Invalid video format' });
    }
    
    const contentType = mimeTypeMatch[1];
    const acceptedTypes = ['video/mp4', 'video/webm', 'video/quicktime'];
    
    if (!acceptedTypes.includes(contentType)) {
      return res.status(400).json({ error: 'Invalid video format. Use MP4, WebM, or MOV.' });
    }

    const videoData = base64Video.replace(/^data:[^;]+;base64,/, '');
    const videoBuffer = Buffer.from(videoData, 'base64');

    const sizeLimit = 50 * 1024 * 1024;
    if (videoBuffer.length > sizeLimit) {
      return res.status(400).json({ error: 'Video file too large. Max 50MB.' });
    }

    if (projectData.video_url) {
      try {
        const urlParts = projectData.video_url.split('/project-videos/');
        const existingPath = urlParts.length > 1 ? urlParts[1] : null;
        if (existingPath) {
          await supabase.storage.from('project-videos').remove([existingPath]);
        }
      } catch (err) {
        console.warn('Failed to remove old video:', err);
      }
    }

    const mimeSubtype = contentType.split('/')[1];
    const extension = mimeSubtype === 'quicktime' ? 'mov' : mimeSubtype;
    const storagePath = `videos/${projectId}/${Date.now()}.${extension}`;
    
    const { error: uploadErr } = await supabase.storage
      .from('project-videos')
      .upload(storagePath, videoBuffer, {
        contentType: contentType,
        upsert: false
      });

    if (uploadErr) {
      console.error('Video upload error:', uploadErr);
      return res.status(500).json({ error: 'Failed to upload video' });
    }

    const { data: urlData } = supabase.storage
      .from('project-videos')
      .getPublicUrl(storagePath);

    let thumbUrl = null;

    if (thumbnailBase64) {
      const thumbData = thumbnailBase64.replace(/^data:[^;]+;base64,/, '');
      const thumbBuffer = Buffer.from(thumbData, 'base64');
      const thumbPath = `thumbnails/${projectId}/${Date.now()}.jpg`;

      const { error: thumbErr } = await supabase.storage
        .from('project-videos')
        .upload(thumbPath, thumbBuffer, {
          contentType: 'image/jpeg',
          upsert: false
        });

      if (!thumbErr) {
        const { data: thumbUrlData } = supabase.storage
          .from('project-videos')
          .getPublicUrl(thumbPath);
        thumbUrl = thumbUrlData.publicUrl;
      }
    }

    await supabase
      .from('projects')
      .update({
        video_url: urlData.publicUrl,
        video_thumbnail_url: thumbUrl,
        video_file_size: videoBuffer.length,
        updated_at: new Date().toISOString()
      })
      .eq('id', projectId);

    res.json({
      video_url: urlData.publicUrl,
      thumbnail_url: thumbUrl
    });

  } catch (error) {
    console.error('Video upload error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Remove video attachment from project
app.delete('/api/projects/:id/video', authenticateToken, async (req, res) => {
  const projectId = req.params.id;

  try {
    const { data: projectData, error: fetchErr } = await supabase
      .from('projects')
      .select('owner_id, video_url, video_thumbnail_url')
      .eq('id', projectId)
      .single();

    if (fetchErr || !projectData) {
      return res.status(404).json({ error: 'Project not found' });
    }

    if (projectData.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    if (projectData.video_url) {
      try {
        const urlParts = projectData.video_url.split('/project-videos/');
        const videoStoragePath = urlParts.length > 1 ? urlParts[1] : null;
        if (videoStoragePath) {
          await supabase.storage.from('project-videos').remove([videoStoragePath]);
        }
      } catch (err) {
        console.warn('Failed to remove video:', err);
      }
    }

    if (projectData.video_thumbnail_url) {
      try {
        const urlParts = projectData.video_thumbnail_url.split('/project-videos/');
        const thumbStoragePath = urlParts.length > 1 ? urlParts[1] : null;
        if (thumbStoragePath) {
          await supabase.storage.from('project-videos').remove([thumbStoragePath]);
        }
      } catch (err) {
        console.warn('Failed to remove thumbnail:', err);
      }
    }

    await supabase
      .from('projects')
      .update({
        video_url: null,
        video_thumbnail_url: null,
        video_file_size: null,
        video_duration: null,
        updated_at: new Date().toISOString()
      })
      .eq('id', projectId);

    res.json({ message: 'Video deleted successfully' });

  } catch (error) {
    console.error('Video delete error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Application routes
app.get('/api/projects/:id/applications', authenticateToken, async (req, res) => {
  try {
    const { data: applications, error } = await supabase
      .from('applications')
      .select(`
        *,
        profiles!applications_user_id_fkey(name, reputation_points)
      `)
      .eq('project_id', req.params.id)
      .order('match_score', { ascending: false })
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Get applications error:', error);
      return res.status(500).json({ error: 'Failed to fetch applications' });
    }

    // Format response to match expected structure
    const formattedApplications = applications.map(a => ({
      ...a,
      applicant_name: a.profiles?.name || 'Unknown',
      reputation_points: a.profiles?.reputation_points || 0
    }));

    res.json(formattedApplications);
  } catch (error) {
    console.error('Get applications error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/projects/:id/apply', authenticateToken, async (req, res) => {
  const { message } = req.body;
  const projectId = req.params.id;

  try {
    // Get project required skills
    const { data: project, error: projectError } = await supabase
      .from('projects')
      .select('required_skills')
      .eq('id', projectId)
      .single();

    if (projectError || !project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const requiredSkills = project.required_skills || [];
    
    // Get user skills
    const { data: userSkills, error: skillsError } = await supabase
      .from('user_skills')
      .select('skill')
      .eq('user_id', req.user.id);

    if (skillsError) {
      return res.status(500).json({ error: 'Failed to calculate match' });
    }

    // Calculate match score
    const userSkillSet = new Set((userSkills || []).map(s => s.skill.toLowerCase()));
    const matchingSkills = requiredSkills.filter(skill => 
      userSkillSet.has(skill.toLowerCase())
    );
    const matchScore = requiredSkills.length > 0 
      ? Math.round((matchingSkills.length / requiredSkills.length) * 100)
      : 50;

    // Insert application
    const { data, error } = await supabase
      .from('applications')
      .insert({
        project_id: projectId,
        user_id: req.user.id,
        message,
        match_score: matchScore,
        status: 'pending'
      })
      .select()
      .single();

    if (error) {
      console.error('Create application error:', error);
      return res.status(500).json({ error: 'Failed to submit application' });
    }

    res.json(data);
  } catch (error) {
    console.error('Apply error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.put('/api/applications/:id/status', authenticateToken, async (req, res) => {
  const { status } = req.body;
  
  try {
    const { error } = await supabase
      .from('applications')
      .update({ status })
      .eq('id', req.params.id);

    if (error) {
      console.error('Update application error:', error);
      return res.status(500).json({ error: 'Failed to update application' });
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Update application status error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Contribution routes
app.get('/api/projects/:id/contributions', async (req, res) => {
  try {
    const { data: contributions, error } = await supabase
      .from('contributions')
      .select(`
        *,
        profiles!contributions_user_id_fkey(name)
      `)
      .eq('project_id', req.params.id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Get contributions error:', error);
      return res.status(500).json({ error: 'Failed to fetch contributions' });
    }

    // Format response to match expected structure
    const formattedContributions = contributions.map(c => ({
      ...c,
      contributor_name: c.profiles?.name || 'Unknown'
    }));

    res.json(formattedContributions);
  } catch (error) {
    console.error('Get contributions error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.get('/api/users/:id/contributions', async (req, res) => {
  try {
    const { data: contributions, error } = await supabase
      .from('contributions')
      .select(`
        *,
        projects!contributions_project_id_fkey(title)
      `)
      .eq('user_id', req.params.id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Get user contributions error:', error);
      return res.status(500).json({ error: 'Failed to fetch contributions' });
    }

    // Format response to match expected structure
    const formattedContributions = contributions.map(c => ({
      ...c,
      project_title: c.projects?.title || 'Unknown'
    }));

    res.json(formattedContributions);
  } catch (error) {
    console.error('Get user contributions error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/projects/:id/contributions', authenticateToken, async (req, res) => {
  const { description, points } = req.body;
  const projectId = req.params.id;
  const contributionPoints = points || 10;

  try {
    // Insert contribution
    const { data: contribution, error: contributionError } = await supabase
      .from('contributions')
      .insert({
        project_id: projectId,
        user_id: req.user.id,
        description,
        points: contributionPoints
      })
      .select()
      .single();

    if (contributionError) {
      console.error('Create contribution error:', contributionError);
      return res.status(500).json({ error: 'Failed to add contribution' });
    }

    // Update user reputation points
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('reputation_points, badges')
      .eq('id', req.user.id)
      .single();

    if (!profileError && profile) {
      const newReputation = (profile.reputation_points || 0) + contributionPoints;
      const badges = profile.badges || [];
      let updated = false;

      // Award badges based on reputation
      if (newReputation >= 100 && !badges.includes('Contributor')) {
        badges.push('Contributor');
        updated = true;
      }
      if (newReputation >= 500 && !badges.includes('Expert')) {
        badges.push('Expert');
        updated = true;
      }
      if (newReputation >= 1000 && !badges.includes('Master')) {
        badges.push('Master');
        updated = true;
      }

      // Update profile
      await supabase
        .from('profiles')
        .update({
          reputation_points: newReputation,
          badges: updated ? badges : profile.badges
        })
        .eq('id', req.user.id);
    }

    res.json(contribution);
  } catch (error) {
    console.error('Add contribution error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Project roles routes

// Get all roles for a project, grouped by category
app.get('/api/projects/:id/roles', async (req, res) => {
  try {
    const { data: roles, error } = await supabase
      .from('project_roles')
      .select('*')
      .eq('project_id', req.params.id)
      .order('display_order', { ascending: true })
      .order('created_at', { ascending: true });

    if (error) {
      console.error('Get project roles error:', error);
      return res.status(500).json({ error: 'Failed to fetch project roles' });
    }

    // Group by category
    const grouped = {};
    (roles || []).forEach(role => {
      if (!grouped[role.role_category]) {
        grouped[role.role_category] = [];
      }
      grouped[role.role_category].push(role);
    });

    res.json(grouped);
  } catch (error) {
    console.error('Get project roles error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Add a role to a project (owner only)
app.post('/api/projects/:id/roles', authenticateToken, async (req, res) => {
  const projectId = req.params.id;
  const { role_category, role_title, description, skills_required, display_order } = req.body;

  if (!role_category || !role_title) {
    return res.status(400).json({ error: 'role_category and role_title are required' });
  }

  try {
    // Verify ownership
    const { data: project, error: projectError } = await supabase
      .from('projects')
      .select('owner_id, total_roles_needed')
      .eq('id', projectId)
      .single();

    if (projectError || !project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    if (project.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const { data: role, error: insertError } = await supabase
      .from('project_roles')
      .insert({
        project_id: projectId,
        role_category,
        role_title,
        description: description || null,
        skills_required: skills_required || [],
        display_order: display_order || 0,
      })
      .select()
      .single();

    if (insertError) {
      console.error('Create project role error:', insertError);
      return res.status(500).json({ error: 'Failed to create role' });
    }

    // Update total_roles_needed count
    await supabase
      .from('projects')
      .update({ total_roles_needed: (project.total_roles_needed || 0) + 1 })
      .eq('id', projectId);

    res.json(role);
  } catch (error) {
    console.error('Create project role error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update a role (owner only)
app.put('/api/projects/:id/roles/:roleId', authenticateToken, async (req, res) => {
  const { id: projectId, roleId } = req.params;
  const { role_category, role_title, description, skills_required, is_filled, filled_by, display_order } = req.body;

  try {
    // Verify ownership
    const { data: project, error: projectError } = await supabase
      .from('projects')
      .select('owner_id')
      .eq('id', projectId)
      .single();

    if (projectError || !project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    if (project.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const updateFields = {};
    if (role_category !== undefined) updateFields.role_category = role_category;
    if (role_title !== undefined) updateFields.role_title = role_title;
    if (description !== undefined) updateFields.description = description;
    if (skills_required !== undefined) updateFields.skills_required = skills_required;
    if (is_filled !== undefined) updateFields.is_filled = is_filled;
    if (filled_by !== undefined) updateFields.filled_by = filled_by;
    if (display_order !== undefined) updateFields.display_order = display_order;

    const { data: role, error: updateError } = await supabase
      .from('project_roles')
      .update(updateFields)
      .eq('id', roleId)
      .eq('project_id', projectId)
      .select()
      .single();

    if (updateError) {
      console.error('Update project role error:', updateError);
      return res.status(500).json({ error: 'Failed to update role' });
    }

    // Recalculate roles_filled count
    const { count } = await supabase
      .from('project_roles')
      .select('id', { count: 'exact', head: true })
      .eq('project_id', projectId)
      .eq('is_filled', true);

    await supabase
      .from('projects')
      .update({ roles_filled: count || 0 })
      .eq('id', projectId);

    res.json(role);
  } catch (error) {
    console.error('Update project role error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete a role (owner only)
app.delete('/api/projects/:id/roles/:roleId', authenticateToken, async (req, res) => {
  const { id: projectId, roleId } = req.params;

  try {
    // Verify ownership
    const { data: project, error: projectError } = await supabase
      .from('projects')
      .select('owner_id, total_roles_needed')
      .eq('id', projectId)
      .single();

    if (projectError || !project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    if (project.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const { error: deleteError } = await supabase
      .from('project_roles')
      .delete()
      .eq('id', roleId)
      .eq('project_id', projectId);

    if (deleteError) {
      console.error('Delete project role error:', deleteError);
      return res.status(500).json({ error: 'Failed to delete role' });
    }

    // Recalculate counts
    const { count: filledCount } = await supabase
      .from('project_roles')
      .select('id', { count: 'exact', head: true })
      .eq('project_id', projectId)
      .eq('is_filled', true);

    const { count: totalCount } = await supabase
      .from('project_roles')
      .select('id', { count: 'exact', head: true })
      .eq('project_id', projectId);

    await supabase
      .from('projects')
      .update({
        total_roles_needed: totalCount || 0,
        roles_filled: filledCount || 0,
      })
      .eq('id', projectId);

    res.json({ success: true });
  } catch (error) {
    console.error('Delete project role error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Role-specific application routes

// Apply for a specific role
app.post('/api/projects/:projectId/roles/:roleId/apply', authenticateToken, async (req, res) => {
  const { projectId, roleId } = req.params;
  const { message } = req.body;

  if (!message || !message.trim()) {
    return res.status(400).json({ error: 'Message is required' });
  }

  try {
    // Verify project and role exist
    const { data: role, error: roleError } = await supabase
      .from('project_roles')
      .select('id, role_title, skills_required, is_filled, project_id')
      .eq('id', roleId)
      .eq('project_id', projectId)
      .single();

    if (roleError || !role) {
      return res.status(404).json({ error: 'Role not found' });
    }

    if (role.is_filled) {
      return res.status(400).json({ error: 'This role is already filled' });
    }

    // Prevent owner from applying to own project
    const { data: project, error: projectError } = await supabase
      .from('projects')
      .select('owner_id')
      .eq('id', projectId)
      .single();

    if (projectError || !project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    if (project.owner_id === req.user.id) {
      return res.status(400).json({ error: 'Project owners cannot apply to their own project' });
    }

    // Get user skills
    const { data: userSkills } = await supabase
      .from('user_skills')
      .select('skill')
      .eq('user_id', req.user.id);

    // Calculate match score
    const requiredSkills = role.skills_required || [];
    const userSkillSet = new Set((userSkills || []).map(s => s.skill.toLowerCase()));
    const matchingSkills = requiredSkills.filter(skill =>
      userSkillSet.has(skill.toLowerCase())
    );
    const matchScore = requiredSkills.length > 0
      ? Math.round((matchingSkills.length / requiredSkills.length) * 100)
      : 50;

    // Insert application (UNIQUE constraint on role_id+user_id prevents duplicates)
    const { data, error } = await supabase
      .from('role_applications')
      .insert({
        project_id: projectId,
        role_id: roleId,
        user_id: req.user.id,
        message: message.trim(),
        match_score: matchScore,
        status: 'pending',
      })
      .select()
      .single();

    if (error) {
      if (error.code === '23505') {
        return res.status(400).json({ error: 'You have already applied for this role' });
      }
      console.error('Create role application error:', error);
      return res.status(500).json({ error: 'Failed to submit application' });
    }

    res.status(201).json(data);
  } catch (error) {
    console.error('Apply for role error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get all role applications for a project (owner only), grouped by role
app.get('/api/projects/:projectId/role-applications', authenticateToken, async (req, res) => {
  const { projectId } = req.params;

  try {
    // Verify ownership
    const { data: project, error: projectError } = await supabase
      .from('projects')
      .select('owner_id')
      .eq('id', projectId)
      .single();

    if (projectError || !project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    if (project.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const { data: applications, error } = await supabase
      .from('role_applications')
      .select(`
        *,
        profiles!role_applications_user_id_fkey(id, name, avatar_url, reputation_points),
        project_roles!role_applications_role_id_fkey(id, role_title, role_category, skills_required)
      `)
      .eq('project_id', projectId)
      .order('status', { ascending: true })
      .order('match_score', { ascending: false })
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Get role applications error:', error);
      return res.status(500).json({ error: 'Failed to fetch applications' });
    }

    // Format and group by role
    const grouped = {};
    (applications || []).forEach(a => {
      const roleId = a.role_id;
      if (!grouped[roleId]) {
        grouped[roleId] = {
          role_id: roleId,
          role_title: a.project_roles?.role_title || '',
          role_category: a.project_roles?.role_category || '',
          skills_required: a.project_roles?.skills_required || [],
          applications: [],
        };
      }
      grouped[roleId].applications.push({
        id: a.id,
        project_id: a.project_id,
        role_id: a.role_id,
        user_id: a.user_id,
        message: a.message,
        match_score: a.match_score,
        status: a.status,
        created_at: a.created_at,
        updated_at: a.updated_at,
        applicant_name: a.profiles?.name || 'Unknown',
        applicant_avatar_url: a.profiles?.avatar_url || null,
        applicant_id: a.profiles?.id || a.user_id,
        reputation_points: a.profiles?.reputation_points || 0,
      });
    });

    res.json(Object.values(grouped));
  } catch (error) {
    console.error('Get role applications error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get current user's own role applications
app.get('/api/users/me/applications', authenticateToken, async (req, res) => {
  try {
    const { data: applications, error } = await supabase
      .from('role_applications')
      .select(`
        *,
        projects!role_applications_project_id_fkey(id, title, owner_id),
        project_roles!role_applications_role_id_fkey(id, role_title, role_category)
      `)
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Get my applications error:', error);
      return res.status(500).json({ error: 'Failed to fetch applications' });
    }

    const formatted = (applications || []).map(a => ({
      id: a.id,
      project_id: a.project_id,
      role_id: a.role_id,
      message: a.message,
      match_score: a.match_score,
      status: a.status,
      created_at: a.created_at,
      updated_at: a.updated_at,
      project_title: a.projects?.title || '',
      role_title: a.project_roles?.role_title || '',
      role_category: a.project_roles?.role_category || '',
    }));

    res.json(formatted);
  } catch (error) {
    console.error('Get my applications error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Accept a role application (owner only)
app.put('/api/role-applications/:applicationId/accept', authenticateToken, async (req, res) => {
  const { applicationId } = req.params;

  try {
    // Fetch application with role and project info
    const { data: application, error: appError } = await supabase
      .from('role_applications')
      .select(`
        *,
        project_roles!role_applications_role_id_fkey(id, role_title, is_filled),
        projects!role_applications_project_id_fkey(id, owner_id)
      `)
      .eq('id', applicationId)
      .single();

    if (appError || !application) {
      return res.status(404).json({ error: 'Application not found' });
    }

    if (application.projects?.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    if (application.status !== 'pending') {
      return res.status(400).json({ error: 'Application is no longer pending' });
    }

    if (application.project_roles?.is_filled) {
      return res.status(400).json({ error: 'Role is already filled' });
    }

    const roleTitle = application.project_roles?.role_title || '';
    const projectId = application.project_id;
    const roleId = application.role_id;
    const userId = application.user_id;

    // Accept application
    const { error: updateError } = await supabase
      .from('role_applications')
      .update({ status: 'accepted', updated_at: new Date().toISOString() })
      .eq('id', applicationId);

    if (updateError) {
      console.error('Accept application update error:', updateError);
      return res.status(500).json({ error: 'Failed to accept application' });
    }

    // Mark role as filled
    await supabase
      .from('project_roles')
      .update({ is_filled: true, filled_by: userId })
      .eq('id', roleId);

    // Add to project_members (ignore duplicate)
    const { error: memberError } = await supabase
      .from('project_members')
      .upsert({
        project_id: projectId,
        user_id: userId,
        role_id: roleId,
        role_title: roleTitle,
      }, { onConflict: 'project_id,user_id,role_id', ignoreDuplicates: true });

    if (memberError) {
      console.error('Add project member error:', memberError);
    }

    // Auto-reject other pending applications for the same role
    await supabase
      .from('role_applications')
      .update({ status: 'rejected', updated_at: new Date().toISOString() })
      .eq('role_id', roleId)
      .eq('status', 'pending')
      .neq('id', applicationId);

    // Recalculate roles_filled on project
    const { count: filledCount } = await supabase
      .from('project_roles')
      .select('id', { count: 'exact', head: true })
      .eq('project_id', projectId)
      .eq('is_filled', true);

    await supabase
      .from('projects')
      .update({ roles_filled: filledCount || 0 })
      .eq('id', projectId);

    res.json({ success: true, message: `${roleTitle} has been filled!` });
  } catch (error) {
    console.error('Accept application error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Reject a role application (owner only)
app.put('/api/role-applications/:applicationId/reject', authenticateToken, async (req, res) => {
  const { applicationId } = req.params;

  try {
    // Fetch application with project info
    const { data: application, error: appError } = await supabase
      .from('role_applications')
      .select(`
        *,
        projects!role_applications_project_id_fkey(id, owner_id)
      `)
      .eq('id', applicationId)
      .single();

    if (appError || !application) {
      return res.status(404).json({ error: 'Application not found' });
    }

    if (application.projects?.owner_id !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const { error: updateError } = await supabase
      .from('role_applications')
      .update({ status: 'rejected', updated_at: new Date().toISOString() })
      .eq('id', applicationId);

    if (updateError) {
      console.error('Reject application error:', updateError);
      return res.status(500).json({ error: 'Failed to reject application' });
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Reject application error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Withdraw (cancel) own pending application
app.delete('/api/role-applications/:applicationId', authenticateToken, async (req, res) => {
  const { applicationId } = req.params;

  try {
    const { data: application, error: appError } = await supabase
      .from('role_applications')
      .select('id, user_id, status')
      .eq('id', applicationId)
      .single();

    if (appError || !application) {
      return res.status(404).json({ error: 'Application not found' });
    }

    if (application.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    if (application.status !== 'pending') {
      return res.status(400).json({ error: 'Can only withdraw pending applications' });
    }

    await supabase
      .from('role_applications')
      .delete()
      .eq('id', applicationId);

    res.json({ success: true });
  } catch (error) {
    console.error('Withdraw application error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get project team members
app.get('/api/projects/:projectId/members', async (req, res) => {
  const { projectId } = req.params;

  try {
    const { data: members, error } = await supabase
      .from('project_members')
      .select(`
        *,
        profiles!project_members_user_id_fkey(id, name, avatar_url, bio),
        project_roles!project_members_role_id_fkey(id, role_category)
      `)
      .eq('project_id', projectId)
      .order('joined_at', { ascending: true });

    if (error) {
      console.error('Get project members error:', error);
      return res.status(500).json({ error: 'Failed to fetch members' });
    }

    const formatted = (members || []).map(m => ({
      id: m.id,
      project_id: m.project_id,
      user_id: m.user_id,
      role_id: m.role_id,
      role_title: m.role_title,
      role_category: m.project_roles?.role_category || '',
      joined_at: m.joined_at,
      name: m.profiles?.name || 'Unknown',
      avatar_url: m.profiles?.avatar_url || null,
      bio: m.profiles?.bio || null,
    }));

    res.json(formatted);
  } catch (error) {
    console.error('Get project members error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Skill category routes

// Get all skill categories grouped by parent category
app.get('/api/skills/categories', async (req, res) => {
  try {
    const { data: categories, error } = await supabase
      .from('skill_categories')
      .select('*')
      .order('parent_category', { ascending: true })
      .order('display_order', { ascending: true });

    if (error) throw error;

    const grouped = {};
    categories.forEach(skill => {
      if (!grouped[skill.parent_category]) {
        grouped[skill.parent_category] = [];
      }
      grouped[skill.parent_category].push(skill);
    });

    res.json(grouped);
  } catch (error) {
    console.error('Get skill categories error:', error);
    res.status(500).json({ error: 'Failed to fetch skill categories' });
  }
});

// Get skills by parent category
app.get('/api/skills/categories/:parentCategory', async (req, res) => {
  try {
    const { parentCategory } = req.params;

    const { data: skills, error } = await supabase
      .from('skill_categories')
      .select('*')
      .eq('parent_category', parentCategory)
      .order('display_order', { ascending: true });

    if (error) throw error;

    res.json(skills);
  } catch (error) {
    console.error('Get skills by category error:', error);
    res.status(500).json({ error: 'Failed to fetch skills' });
  }
});

// Search skills
app.get('/api/skills/search', async (req, res) => {
  try {
    const { query = '', limit = 20 } = req.query;

    // Sanitize query to prevent SQL injection - escape special characters
    const sanitizedQuery = query.replace(/[\\%_]/g, '\\$&');

    const { data: skills, error } = await supabase
      .from('skill_categories')
      .select('*')
      .or(`name.ilike.%${sanitizedQuery}%,description.ilike.%${sanitizedQuery}%`)
      .limit(limit);

    if (error) throw error;

    res.json(skills);
  } catch (error) {
    console.error('Search skills error:', error);
    res.status(500).json({ error: 'Failed to search skills' });
  }
});

// Update user's primary expertise
app.put('/api/users/me/expertise', authenticateToken, async (req, res) => {
  try {
    const { primary_expertise, expertise_level } = req.body;

    if (!primary_expertise) {
      return res.status(400).json({ error: 'Primary expertise is required' });
    }

    const { data, error } = await supabase
      .from('profiles')
      .update({
        primary_expertise,
        expertise_level: expertise_level || 'intermediate'
      })
      .eq('id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    res.json(data);
  } catch (error) {
    console.error('Update expertise error:', error);
    res.status(500).json({ error: 'Failed to update expertise' });
  }
});

// ─── DISCUSSION ENDPOINTS ────────────────────────────────────────────────────

// Create discussion
app.post('/api/discussions', authenticateToken, async (req, res) => {
  try {
    const { category, title, content, tags, image_url } = req.body;
    if (!category || !title || !content) {
      return res.status(400).json({ error: 'category, title, and content are required' });
    }

    const { data, error } = await supabase
      .from('discussions')
      .insert({
        author_id: req.user.id,
        category,
        title,
        content,
        tags: tags || [],
        image_url: image_url || null,
      })
      .select(`*, profiles:author_id (id, name, avatar_url)`)
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (error) {
    console.error('Create discussion error:', error);
    res.status(500).json({ error: 'Failed to create discussion' });
  }
});

// List discussions
app.get('/api/discussions', async (req, res) => {
  try {
    const { category, search, sort = 'recent' } = req.query;
    const rawPage = parseInt(req.query.page, 10);
    const rawLimit = parseInt(req.query.limit, 10);
    const page = (Number.isFinite(rawPage) && rawPage > 0) ? rawPage : 1;
    const limit = (Number.isFinite(rawLimit) && rawLimit > 0 && rawLimit <= 100) ? rawLimit : 20;

    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    let userId = null;
    if (token) {
      const { data: { user } } = await supabase.auth.getUser(token);
      if (user) userId = user.id;
    }

    const offset = (page - 1) * limit;
    let query = supabase
      .from('discussions')
      .select(`*, profiles:author_id (id, name, avatar_url)`)
      .range(offset, offset + limit - 1);

    if (category) query = query.eq('category', category);
    if (search) {
      // Escape special PostgREST filter characters to prevent injection
      const safeSearch = search.replace(/[%_\\]/g, '\\$&');
      query = query.or(`title.ilike.%${safeSearch}%,content.ilike.%${safeSearch}%`);
    }

    if (sort === 'popular') query = query.order('likes_count', { ascending: false });
    else if (sort === 'trending') query = query.order('views_count', { ascending: false });
    else query = query.order('created_at', { ascending: false });

    const { data: discussions, error } = await query;
    if (error) throw error;

    let likedIds = new Set();
    if (userId) {
      const { data: likes } = await supabase
        .from('discussion_likes')
        .select('discussion_id')
        .eq('user_id', userId)
        .is('reply_id', null);
      if (likes) likes.forEach(l => likedIds.add(l.discussion_id));
    }

    // Fetch media for all discussions in one query
    const discussionIds = (discussions || []).map(d => d.id);
    let mediaByDiscussion = {};
    if (discussionIds.length > 0) {
      const { data: allMedia } = await supabase
        .from('discussion_media')
        .select('*')
        .in('discussion_id', discussionIds)
        .order('display_order', { ascending: true });
      if (allMedia) {
        allMedia.forEach(m => {
          if (!mediaByDiscussion[m.discussion_id]) mediaByDiscussion[m.discussion_id] = [];
          mediaByDiscussion[m.discussion_id].push(m);
        });
      }
    }

    const result = (discussions || []).map(d => ({
      ...d,
      is_liked_by_user: likedIds.has(d.id),
      media: mediaByDiscussion[d.id] || [],
    }));

    res.json(result);
  } catch (error) {
    console.error('List discussions error:', error);
    res.status(500).json({ error: 'Failed to fetch discussions' });
  }
});

// Get single discussion
app.get('/api/discussions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    let userId = null;
    if (token) {
      const { data: { user } } = await supabase.auth.getUser(token);
      if (user) userId = user.id;
    }

    const { data: discussion, error } = await supabase
      .from('discussions')
      .select(`*, profiles:author_id (id, name, avatar_url)`)
      .eq('id', id)
      .single();

    if (error || !discussion) return res.status(404).json({ error: 'Discussion not found' });

    // Increment views (fire and forget)
    supabase.from('discussions')
      .update({ views_count: (discussion.views_count || 0) + 1 })
      .eq('id', id)
      .then(() => {});

    let isLiked = false;
    if (userId) {
      const { data: like } = await supabase
        .from('discussion_likes')
        .select('id')
        .eq('discussion_id', id)
        .eq('user_id', userId)
        .is('reply_id', null)
        .single();
      isLiked = !!like;
    }

    // Fetch media for this discussion
    const { data: media } = await supabase
      .from('discussion_media')
      .select('*')
      .eq('discussion_id', id)
      .order('display_order', { ascending: true })
      .order('created_at', { ascending: true });

    res.json({ ...discussion, is_liked_by_user: isLiked, media: media || [] });
  } catch (error) {
    console.error('Get discussion error:', error);
    res.status(500).json({ error: 'Failed to fetch discussion' });
  }
});

// Add reply to discussion
app.post('/api/discussions/:id/replies', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { content, parent_reply_id } = req.body;
    if (!content) return res.status(400).json({ error: 'content is required' });

    const { data: reply, error } = await supabase
      .from('discussion_replies')
      .insert({
        discussion_id: id,
        author_id: req.user.id,
        parent_reply_id: parent_reply_id || null,
        content,
      })
      .select(`*, profiles:author_id (id, name, avatar_url)`)
      .single();

    if (error) throw error;

    // Increment replies_count (fire and forget)
    supabase.from('discussions').select('replies_count').eq('id', id).single()
      .then(({ data }) => {
        if (data) {
          supabase.from('discussions')
            .update({ replies_count: (data.replies_count || 0) + 1 })
            .eq('id', id).then(() => {});
        }
      });

    res.status(201).json(reply);
  } catch (error) {
    console.error('Add reply error:', error);
    res.status(500).json({ error: 'Failed to add reply' });
  }
});

// Get replies for a discussion
app.get('/api/discussions/:id/replies', async (req, res) => {
  try {
    const { id } = req.params;
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    let userId = null;
    if (token) {
      const { data: { user } } = await supabase.auth.getUser(token);
      if (user) userId = user.id;
    }

    const { data: replies, error } = await supabase
      .from('discussion_replies')
      .select(`*, profiles:author_id (id, name, avatar_url)`)
      .eq('discussion_id', id)
      .order('created_at', { ascending: true });

    if (error) throw error;

    let likedReplyIds = new Set();
    if (userId) {
      const { data: likes } = await supabase
        .from('discussion_likes')
        .select('reply_id')
        .eq('user_id', userId)
        .not('reply_id', 'is', null);
      if (likes) likes.forEach(l => likedReplyIds.add(l.reply_id));
    }

    // Build nested structure
    const topLevel = [];
    const byId = {};
    (replies || []).forEach(r => {
      byId[r.id] = { ...r, is_liked_by_user: likedReplyIds.has(r.id), replies: [] };
    });
    (replies || []).forEach(r => {
      if (r.parent_reply_id && byId[r.parent_reply_id]) {
        byId[r.parent_reply_id].replies.push(byId[r.id]);
      } else {
        topLevel.push(byId[r.id]);
      }
    });

    res.json(topLevel);
  } catch (error) {
    console.error('Get replies error:', error);
    res.status(500).json({ error: 'Failed to fetch replies' });
  }
});

// Like a discussion or reply
app.post('/api/discussions/:id/like', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { reply_id } = req.body;

    // Check for existing like
    let query = supabase
      .from('discussion_likes')
      .select('id')
      .eq('user_id', req.user.id);

    if (reply_id) {
      query = query.eq('reply_id', reply_id);
    } else {
      query = query.eq('discussion_id', id).is('reply_id', null);
    }

    const { data: existing } = await query.single();
    if (existing) return res.status(409).json({ error: 'Already liked' });

    const { error: insertError } = await supabase
      .from('discussion_likes')
      .insert({
        discussion_id: id,
        reply_id: reply_id || null,
        user_id: req.user.id,
      });

    if (insertError) throw insertError;

    if (reply_id) {
      const { data: reply } = await supabase.from('discussion_replies').select('likes_count').eq('id', reply_id).single();
      if (reply) await supabase.from('discussion_replies').update({ likes_count: (reply.likes_count || 0) + 1 }).eq('id', reply_id);
    } else {
      const { data: disc } = await supabase.from('discussions').select('likes_count').eq('id', id).single();
      if (disc) await supabase.from('discussions').update({ likes_count: (disc.likes_count || 0) + 1 }).eq('id', id);
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Like discussion error:', error);
    res.status(500).json({ error: 'Failed to like' });
  }
});

// Unlike a discussion or reply
app.delete('/api/discussions/:id/like', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { reply_id } = req.query;

    let query = supabase
      .from('discussion_likes')
      .delete()
      .eq('user_id', req.user.id);

    if (reply_id) {
      query = query.eq('reply_id', reply_id);
    } else {
      query = query.eq('discussion_id', id).is('reply_id', null);
    }

    const { error } = await query;
    if (error) throw error;

    if (reply_id) {
      const { data: reply } = await supabase.from('discussion_replies').select('likes_count').eq('id', reply_id).single();
      if (reply) await supabase.from('discussion_replies').update({ likes_count: Math.max(0, (reply.likes_count || 0) - 1) }).eq('id', reply_id);
    } else {
      const { data: disc } = await supabase.from('discussions').select('likes_count').eq('id', id).single();
      if (disc) await supabase.from('discussions').update({ likes_count: Math.max(0, (disc.likes_count || 0) - 1) }).eq('id', id);
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Unlike discussion error:', error);
    res.status(500).json({ error: 'Failed to unlike' });
  }
});

// ─── DISCUSSION MEDIA ENDPOINTS ──────────────────────────────────────────────

const DISCUSSION_MEDIA_BUCKET = 'discussion-media';
const MAX_DISCUSSION_MEDIA = 5;
const MAX_IMAGE_SIZE = 10 * 1024 * 1024;   // 10MB
const MAX_VIDEO_SIZE = 100 * 1024 * 1024;  // 100MB
const ACCEPTED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const ACCEPTED_VIDEO_TYPES = ['video/mp4', 'video/webm', 'video/quicktime'];

// Helper: increment or decrement cached media_count on discussions table
async function adjustDiscussionMediaCount(discussionId, delta) {
  try {
    const { data } = await supabase
      .from('discussions')
      .select('media_count')
      .eq('id', discussionId)
      .single();
    if (data) {
      await supabase
        .from('discussions')
        .update({
          media_count: Math.max(0, (data.media_count || 0) + delta),
          updated_at: new Date().toISOString(),
        })
        .eq('id', discussionId);
    }
  } catch (err) {
    console.warn('Failed to adjust media_count:', err.message);
  }
}

// Upload media to a discussion
app.post('/api/discussions/:id/media', authenticateToken, async (req, res) => {
  const discussionId = req.params.id;
  try {
    const { base64File, fileName, thumbnailBase64 } = req.body;

    if (!base64File || !fileName) {
      return res.status(400).json({ error: 'base64File and fileName are required' });
    }

    // Verify discussion exists
    const { data: discussion, error: discErr } = await supabase
      .from('discussions')
      .select('id')
      .eq('id', discussionId)
      .single();

    if (discErr || !discussion) {
      return res.status(404).json({ error: 'Discussion not found' });
    }

    // Check media count limit
    const { count, error: countErr } = await supabase
      .from('discussion_media')
      .select('id', { count: 'exact', head: true })
      .eq('discussion_id', discussionId);

    if (!countErr && count >= MAX_DISCUSSION_MEDIA) {
      return res.status(400).json({ error: `Maximum ${MAX_DISCUSSION_MEDIA} media files allowed per discussion` });
    }

    // Parse mime type from base64 data URI
    const mimeMatch = base64File.match(/^data:(.+);base64,/);
    if (!mimeMatch) {
      return res.status(400).json({ error: 'Invalid file format' });
    }
    const mimeType = mimeMatch[1];

    const isImage = ACCEPTED_IMAGE_TYPES.includes(mimeType);
    const isVideo = ACCEPTED_VIDEO_TYPES.includes(mimeType);

    if (!isImage && !isVideo) {
      return res.status(400).json({ error: 'Unsupported file type. Use JPEG, PNG, GIF, WebP, MP4, WebM, or MOV.' });
    }

    // Convert base64 to buffer and check size
    const fileData = base64File.replace(/^data:[^;]+;base64,/, '');
    const fileBuffer = Buffer.from(fileData, 'base64');

    if (isImage && fileBuffer.length > MAX_IMAGE_SIZE) {
      return res.status(400).json({ error: 'Image too large. Maximum size is 10MB.' });
    }
    if (isVideo && fileBuffer.length > MAX_VIDEO_SIZE) {
      return res.status(400).json({ error: 'Video too large. Maximum size is 100MB.' });
    }

    const mediaType = isImage ? 'image' : 'video';
    const mimeSubtype = mimeType.split('/')[1];
    const safeFileName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_').toLowerCase();
    const folder = isImage ? 'images' : 'videos';
    // Include random hex to prevent timestamp collisions on concurrent uploads
    const uniquePrefix = `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
    const storagePath = `${req.user.id}/${folder}/${uniquePrefix}_${safeFileName}`;

    const { error: uploadErr } = await supabase.storage
      .from(DISCUSSION_MEDIA_BUCKET)
      .upload(storagePath, fileBuffer, { contentType: mimeType, upsert: false });

    if (uploadErr) {
      console.error('Discussion media upload error:', uploadErr);
      return res.status(500).json({ error: 'Failed to upload file' });
    }

    const { data: urlData } = supabase.storage
      .from(DISCUSSION_MEDIA_BUCKET)
      .getPublicUrl(storagePath);

    let thumbnailUrl = null;

    // Upload thumbnail for videos (or if provided for images)
    if (thumbnailBase64) {
      try {
        const thumbData = thumbnailBase64.replace(/^data:[^;]+;base64,/, '');
        const thumbBuffer = Buffer.from(thumbData, 'base64');
        const thumbPath = `${req.user.id}/thumbnails/${uniquePrefix}_${safeFileName}_thumb.jpg`;

        const { error: thumbErr } = await supabase.storage
          .from(DISCUSSION_MEDIA_BUCKET)
          .upload(thumbPath, thumbBuffer, { contentType: 'image/jpeg', upsert: false });

        if (!thumbErr) {
          const { data: thumbUrlData } = supabase.storage
            .from(DISCUSSION_MEDIA_BUCKET)
            .getPublicUrl(thumbPath);
          thumbnailUrl = thumbUrlData.publicUrl;
        }
      } catch (thumbEx) {
        console.warn('Thumbnail upload failed (non-fatal):', thumbEx.message);
      }
    }

    // Insert metadata into discussion_media table
    const { data: mediaRecord, error: insertErr } = await supabase
      .from('discussion_media')
      .insert({
        discussion_id: discussionId,
        media_type: mediaType,
        file_url: urlData.publicUrl,
        thumbnail_url: thumbnailUrl,
        file_name: fileName,
        file_size: fileBuffer.length,
        mime_type: mimeType,
        uploaded_by: req.user.id,
        display_order: count || 0,
      })
      .select()
      .single();

    if (insertErr) {
      // Clean up uploaded file on DB error
      await supabase.storage.from(DISCUSSION_MEDIA_BUCKET).remove([storagePath]);
      throw insertErr;
    }

    // Update cached media_count on discussions table (fire and forget)
    adjustDiscussionMediaCount(discussionId, +1);

    res.status(201).json(mediaRecord);
  } catch (error) {
    console.error('Discussion media upload error:', error);
    res.status(500).json({ error: 'Failed to upload media' });
  }
});

// Get all media for a discussion
app.get('/api/discussions/:id/media', async (req, res) => {
  const discussionId = req.params.id;
  try {
    const { data, error } = await supabase
      .from('discussion_media')
      .select('*')
      .eq('discussion_id', discussionId)
      .order('display_order', { ascending: true })
      .order('created_at', { ascending: true });

    if (error) throw error;
    res.json(data || []);
  } catch (error) {
    console.error('Get discussion media error:', error);
    res.status(500).json({ error: 'Failed to fetch media' });
  }
});

// Delete a media item from a discussion
app.delete('/api/discussions/:id/media/:mediaId', authenticateToken, async (req, res) => {
  const { id: discussionId, mediaId } = req.params;
  try {
    const { data: mediaRecord, error: fetchErr } = await supabase
      .from('discussion_media')
      .select('*')
      .eq('id', mediaId)
      .eq('discussion_id', discussionId)
      .single();

    if (fetchErr || !mediaRecord) {
      return res.status(404).json({ error: 'Media not found' });
    }

    if (mediaRecord.uploaded_by !== req.user.id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    // Remove file from storage
    if (mediaRecord.file_url) {
      try {
        const bucketPrefix = `/${DISCUSSION_MEDIA_BUCKET}/`;
        const urlParts = mediaRecord.file_url.split(bucketPrefix);
        const storagePath = urlParts.length > 1 ? urlParts[1] : null;
        if (storagePath) {
          await supabase.storage.from(DISCUSSION_MEDIA_BUCKET).remove([storagePath]);
        }
      } catch (err) {
        console.warn('Failed to remove media file from storage:', err);
      }
    }

    // Remove thumbnail from storage
    if (mediaRecord.thumbnail_url) {
      try {
        const bucketPrefix = `/${DISCUSSION_MEDIA_BUCKET}/`;
        const urlParts = mediaRecord.thumbnail_url.split(bucketPrefix);
        const thumbPath = urlParts.length > 1 ? urlParts[1] : null;
        if (thumbPath) {
          await supabase.storage.from(DISCUSSION_MEDIA_BUCKET).remove([thumbPath]);
        }
      } catch (err) {
        console.warn('Failed to remove thumbnail from storage:', err);
      }
    }

    // Delete database record
    const { error: deleteErr } = await supabase
      .from('discussion_media')
      .delete()
      .eq('id', mediaId);

    if (deleteErr) throw deleteErr;

    // Update cached media_count on discussions (fire and forget)
    adjustDiscussionMediaCount(discussionId, -1);

    res.json({ success: true });
  } catch (error) {
    console.error('Delete discussion media error:', error);
    res.status(500).json({ error: 'Failed to delete media' });
  }
});

// ─── LIVE EVENT ENDPOINTS ────────────────────────────────────────────────────

// Create live event
app.post('/api/live-events', authenticateToken, async (req, res) => {
  try {
    const {
      title, description, category, event_type,
      scheduled_start, scheduled_end, timezone,
      meeting_link, max_attendees, allow_chat, allow_reactions,
    } = req.body;

    if (!title || !category || !event_type) {
      return res.status(400).json({ error: 'title, category, and event_type are required' });
    }

    const { data, error } = await supabase
      .from('live_events')
      .insert({
        host_id: req.user.id,
        title,
        description: description || null,
        category,
        event_type,
        scheduled_start: scheduled_start || null,
        scheduled_end: scheduled_end || null,
        timezone: timezone || 'UTC',
        meeting_link: meeting_link || null,
        max_attendees: max_attendees || 100,
        allow_chat: allow_chat !== false,
        allow_reactions: allow_reactions !== false,
      })
      .select(`*, profiles:host_id (id, name, avatar_url)`)
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (error) {
    console.error('Create live event error:', error);
    res.status(500).json({ error: 'Failed to create live event' });
  }
});

// List live events
app.get('/api/live-events', async (req, res) => {
  try {
    const { status, category, host_id } = req.query;
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    let userId = null;
    if (token) {
      const { data: { user } } = await supabase.auth.getUser(token);
      if (user) userId = user.id;
    }

    let query = supabase
      .from('live_events')
      .select(`*, profiles:host_id (id, name, avatar_url)`);

    if (category) query = query.eq('category', category);
    if (host_id) query = query.eq('host_id', host_id);

    if (status === 'live') {
      query = query.eq('is_live', true);
    } else if (status === 'upcoming') {
      // Events not yet started and not ended (scheduled in future or with no scheduled time yet)
      query = query.eq('is_live', false).is('ended_at', null)
        .or('scheduled_start.is.null,scheduled_start.gt.' + new Date().toISOString());
    } else if (status === 'past') {
      query = query.not('ended_at', 'is', null);
    }

    // Live events first, then by scheduled_start
    query = query.order('is_live', { ascending: false }).order('scheduled_start', { ascending: true });

    const { data: events, error } = await query;
    if (error) throw error;

    // Attach RSVP counts
    const eventIds = (events || []).map(e => e.id);
    let rsvpCounts = {};
    let userRsvps = {};
    if (eventIds.length) {
      const { data: rsvps } = await supabase
        .from('event_rsvps')
        .select('event_id, status, user_id')
        .in('event_id', eventIds);
      if (rsvps) {
        rsvps.forEach(r => {
          if (!rsvpCounts[r.event_id]) rsvpCounts[r.event_id] = 0;
          rsvpCounts[r.event_id]++;
          if (userId && r.user_id === userId) userRsvps[r.event_id] = r.status;
        });
      }
    }

    const result = (events || []).map(e => ({
      ...e,
      rsvp_count: rsvpCounts[e.id] || 0,
      user_rsvp_status: userRsvps[e.id] || null,
    }));

    res.json(result);
  } catch (error) {
    console.error('List live events error:', error);
    res.status(500).json({ error: 'Failed to fetch live events' });
  }
});

// Get single live event
app.get('/api/live-events/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    let userId = null;
    if (token) {
      const { data: { user } } = await supabase.auth.getUser(token);
      if (user) userId = user.id;
    }

    const { data: event, error } = await supabase
      .from('live_events')
      .select(`*, profiles:host_id (id, name, avatar_url)`)
      .eq('id', id)
      .single();

    if (error || !event) return res.status(404).json({ error: 'Event not found' });

    // Increment total_views if not the host (fire and forget)
    if (!userId || userId !== event.host_id) {
      supabase.from('live_events')
        .update({ total_views: (event.total_views || 0) + 1 })
        .eq('id', id).then(() => {});
    }

    // Get RSVP count and user's RSVP status
    const { data: rsvps } = await supabase.from('event_rsvps').select('user_id, status').eq('event_id', id);
    const rsvpCount = (rsvps || []).length;
    const userRsvp = userId ? (rsvps || []).find(r => r.user_id === userId) : null;

    res.json({
      ...event,
      rsvp_count: rsvpCount,
      user_rsvp_status: userRsvp ? userRsvp.status : null,
    });
  } catch (error) {
    console.error('Get live event error:', error);
    res.status(500).json({ error: 'Failed to fetch live event' });
  }
});

// Go live
app.post('/api/live-events/:id/go-live', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { stream_url } = req.body;

    const { data: event } = await supabase.from('live_events').select('host_id').eq('id', id).single();
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (event.host_id !== req.user.id) return res.status(403).json({ error: 'Only the host can go live' });

    const { data, error } = await supabase
      .from('live_events')
      .update({ is_live: true, started_at: new Date().toISOString(), stream_url: stream_url || null })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    console.error('Go live error:', error);
    res.status(500).json({ error: 'Failed to start live stream' });
  }
});

// End stream
app.post('/api/live-events/:id/end', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { recording_url } = req.body;

    const { data: event } = await supabase.from('live_events').select('host_id, viewers_count, peak_viewers').eq('id', id).single();
    if (!event) return res.status(404).json({ error: 'Event not found' });
    if (event.host_id !== req.user.id) return res.status(403).json({ error: 'Only the host can end the stream' });

    const { data, error } = await supabase
      .from('live_events')
      .update({
        is_live: false,
        ended_at: new Date().toISOString(),
        recording_url: recording_url || null,
        peak_viewers: Math.max(event.viewers_count || 0, event.peak_viewers || 0),
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    console.error('End stream error:', error);
    res.status(500).json({ error: 'Failed to end stream' });
  }
});

// RSVP to event
app.post('/api/live-events/:id/rsvp', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status = 'attending' } = req.body;

    if (!['attending', 'maybe', 'not_attending'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const { data, error } = await supabase
      .from('event_rsvps')
      .upsert({ event_id: id, user_id: req.user.id, status, updated_at: new Date().toISOString() })
      .select()
      .single();

    if (error) throw error;
    res.json(data);
  } catch (error) {
    console.error('RSVP error:', error);
    res.status(500).json({ error: 'Failed to RSVP' });
  }
});

// Remove RSVP
app.delete('/api/live-events/:id/rsvp', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { error } = await supabase
      .from('event_rsvps')
      .delete()
      .eq('event_id', id)
      .eq('user_id', req.user.id);

    if (error) throw error;
    res.json({ success: true });
  } catch (error) {
    console.error('Remove RSVP error:', error);
    res.status(500).json({ error: 'Failed to remove RSVP' });
  }
});

// Get chat messages
app.get('/api/live-events/:id/chat', async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await supabase
      .from('live_chat_messages')
      .select(`*, profiles:user_id (id, name, avatar_url)`)
      .eq('event_id', id)
      .order('created_at', { ascending: false })
      .limit(100);

    if (error) throw error;
    res.json((data || []).reverse());
  } catch (error) {
    console.error('Get chat error:', error);
    res.status(500).json({ error: 'Failed to fetch chat' });
  }
});

// Send chat message
app.post('/api/live-events/:id/chat', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { message } = req.body;
    if (!message) return res.status(400).json({ error: 'message is required' });

    const { data, error } = await supabase
      .from('live_chat_messages')
      .insert({ event_id: id, user_id: req.user.id, message })
      .select(`*, profiles:user_id (id, name, avatar_url)`)
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (error) {
    console.error('Send chat error:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

// Send reaction
app.post('/api/live-events/:id/reaction', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { reaction_type } = req.body;
    const validTypes = ['like', 'love', 'fire', 'clap', 'think'];
    if (!reaction_type || !validTypes.includes(reaction_type)) {
      return res.status(400).json({ error: 'Valid reaction_type required' });
    }

    const { data, error } = await supabase
      .from('live_reactions')
      .insert({ event_id: id, user_id: req.user.id, reaction_type })
      .select()
      .single();

    if (error) throw error;
    res.status(201).json(data);
  } catch (error) {
    console.error('Send reaction error:', error);
    res.status(500).json({ error: 'Failed to send reaction' });
  }
});

// Get viewer count
app.get('/api/live-events/:id/viewers', async (req, res) => {
  try {
    const { id } = req.params;
    const { data, error } = await supabase
      .from('live_events')
      .select('viewers_count')
      .eq('id', id)
      .single();

    if (error) throw error;
    res.json({ viewers_count: data?.viewers_count || 0 });
  } catch (error) {
    console.error('Get viewers error:', error);
    res.status(500).json({ error: 'Failed to get viewer count' });
  }
});

// Serve frontend for root path
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../client/public/index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
