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

// Get user profile by ID
app.get('/api/users/:id', async (req, res) => {
  try {
    const { data: profile, error } = await supabase
      .from('profiles')
      .select('id, name, username, bio, avatar_url, location, industry, skills, role, reputation_points, badges, created_at')
      .eq('id', req.params.id)
      .single();

    if (error || !profile) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(profile);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update user profile
app.put('/api/users/me', authenticateToken, async (req, res) => {
  const { name, username, bio, location, industry, skills, avatar_url } = req.body;

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

// Search users
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
        profiles!projects_owner_id_fkey(name)
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
      owner_name: p.profiles?.name || 'Unknown'
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
        profiles!projects_owner_id_fkey(name)
      `)
      .eq('id', req.params.id)
      .single();

    if (error || !project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    // Format response to match expected structure
    res.json({
      ...project,
      owner_name: project.profiles?.name || 'Unknown'
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

    const extension = contentType.split('/')[1] === 'quicktime' ? 'mov' : contentType.split('/')[1];
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

// Serve frontend for root path
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../client/public/index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
