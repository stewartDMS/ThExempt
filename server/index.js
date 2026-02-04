const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Validate JWT_SECRET is set
if (!process.env.JWT_SECRET) {
  console.error('FATAL ERROR: JWT_SECRET is not defined in environment variables.');
  console.error('Please set JWT_SECRET in your .env file before starting the server.');
  process.exit(1);
}

const JWT_SECRET = process.env.JWT_SECRET;

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
app.use(bodyParser.json());
app.use('/api/', apiLimiter);
app.use(express.static(path.join(__dirname, '../client/public')));

// Database setup
const db = new sqlite3.Database('./thexempt.db', (err) => {
  if (err) {
    console.error('Error opening database:', err);
  } else {
    console.log('Database connected');
    initializeDatabase();
  }
});

// Initialize database tables
function initializeDatabase() {
  db.serialize(() => {
    // Users table
    db.run(`CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      name TEXT NOT NULL,
      role TEXT DEFAULT 'member',
      reputation_points INTEGER DEFAULT 0,
      badges TEXT DEFAULT '[]',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Projects table
    db.run(`CREATE TABLE IF NOT EXISTS projects (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      owner_id INTEGER NOT NULL,
      status TEXT DEFAULT 'open',
      required_skills TEXT DEFAULT '[]',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (owner_id) REFERENCES users(id)
    )`);

    // Applications table
    db.run(`CREATE TABLE IF NOT EXISTS applications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      status TEXT DEFAULT 'pending',
      message TEXT,
      match_score INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (project_id) REFERENCES projects(id),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`);

    // Contributions table
    db.run(`CREATE TABLE IF NOT EXISTS contributions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      description TEXT NOT NULL,
      points INTEGER DEFAULT 10,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (project_id) REFERENCES projects(id),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`);

    // User skills table
    db.run(`CREATE TABLE IF NOT EXISTS user_skills (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      skill TEXT NOT NULL,
      proficiency INTEGER DEFAULT 1,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )`);
  });
}

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Authentication required - No token provided' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Auth routes
app.post('/api/auth/signup', authLimiter, async (req, res) => {
  const { email, password, name } = req.body;

  if (!email || !password || !name) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    
    db.run(
      'INSERT INTO users (email, password, name) VALUES (?, ?, ?)',
      [email, hashedPassword, name],
      function(err) {
        if (err) {
          if (err.message.includes('UNIQUE')) {
            return res.status(400).json({ error: 'Email already exists' });
          }
          return res.status(500).json({ error: 'Failed to create user' });
        }

        const token = jwt.sign({ id: this.lastID, email }, JWT_SECRET, { expiresIn: '7d' });
        res.json({
          token,
          user: { id: this.lastID, email, name, reputation_points: 0, badges: [] }
        });
      }
    );
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

app.post('/api/auth/login', authLimiter, (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
    if (err || !user) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        reputation_points: user.reputation_points,
        badges: JSON.parse(user.badges || '[]')
      }
    });
  });
});

// User routes
app.get('/api/users/me', authenticateToken, (req, res) => {
  db.get('SELECT id, email, name, role, reputation_points, badges FROM users WHERE id = ?',
    [req.user.id],
    (err, user) => {
      if (err || !user) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.json({
        ...user,
        badges: JSON.parse(user.badges || '[]')
      });
    }
  );
});

app.get('/api/users/:id/skills', (req, res) => {
  db.all('SELECT skill, proficiency FROM user_skills WHERE user_id = ?',
    [req.params.id],
    (err, skills) => {
      if (err) {
        return res.status(500).json({ error: 'Failed to fetch skills' });
      }
      res.json(skills);
    }
  );
});

app.post('/api/users/skills', authenticateToken, (req, res) => {
  const { skill, proficiency } = req.body;
  
  db.run(
    'INSERT INTO user_skills (user_id, skill, proficiency) VALUES (?, ?, ?)',
    [req.user.id, skill, proficiency || 1],
    function(err) {
      if (err) {
        return res.status(500).json({ error: 'Failed to add skill' });
      }
      res.json({ id: this.lastID, skill, proficiency });
    }
  );
});

// Project routes
app.get('/api/projects', (req, res) => {
  const query = `
    SELECT p.*, u.name as owner_name
    FROM projects p
    JOIN users u ON p.owner_id = u.id
    WHERE p.status = 'open'
    ORDER BY p.created_at DESC
  `;
  
  db.all(query, [], (err, projects) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to fetch projects' });
    }
    res.json(projects.map(p => ({
      ...p,
      required_skills: JSON.parse(p.required_skills || '[]')
    })));
  });
});

app.get('/api/projects/:id', (req, res) => {
  const query = `
    SELECT p.*, u.name as owner_name
    FROM projects p
    JOIN users u ON p.owner_id = u.id
    WHERE p.id = ?
  `;
  
  db.get(query, [req.params.id], (err, project) => {
    if (err || !project) {
      return res.status(404).json({ error: 'Project not found' });
    }
    res.json({
      ...project,
      required_skills: JSON.parse(project.required_skills || '[]')
    });
  });
});

app.post('/api/projects', authenticateToken, (req, res) => {
  const { title, description, required_skills } = req.body;

  if (!title || !description) {
    return res.status(400).json({ error: 'Title and description are required' });
  }

  db.run(
    'INSERT INTO projects (title, description, owner_id, required_skills) VALUES (?, ?, ?, ?)',
    [title, description, req.user.id, JSON.stringify(required_skills || [])],
    function(err) {
      if (err) {
        return res.status(500).json({ error: 'Failed to create project' });
      }
      res.json({
        id: this.lastID,
        title,
        description,
        owner_id: req.user.id,
        required_skills: required_skills || [],
        status: 'open'
      });
    }
  );
});

// Application routes
app.get('/api/projects/:id/applications', authenticateToken, (req, res) => {
  const query = `
    SELECT a.*, u.name as applicant_name, u.reputation_points
    FROM applications a
    JOIN users u ON a.user_id = u.id
    WHERE a.project_id = ?
    ORDER BY a.match_score DESC, a.created_at DESC
  `;
  
  db.all(query, [req.params.id], (err, applications) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to fetch applications' });
    }
    res.json(applications);
  });
});

app.post('/api/projects/:id/apply', authenticateToken, (req, res) => {
  const { message } = req.body;
  const projectId = req.params.id;

  // Calculate match score using AI-assisted matching (basic rule engine)
  db.get('SELECT required_skills FROM projects WHERE id = ?', [projectId], (err, project) => {
    if (err || !project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const requiredSkills = JSON.parse(project.required_skills || '[]');
    
    db.all('SELECT skill FROM user_skills WHERE user_id = ?', [req.user.id], (err, userSkills) => {
      if (err) {
        return res.status(500).json({ error: 'Failed to calculate match' });
      }

      // Simple matching algorithm: count matching skills
      const userSkillSet = new Set(userSkills.map(s => s.skill.toLowerCase()));
      const matchingSkills = requiredSkills.filter(skill => 
        userSkillSet.has(skill.toLowerCase())
      );
      const matchScore = requiredSkills.length > 0 
        ? Math.round((matchingSkills.length / requiredSkills.length) * 100)
        : 50;

      db.run(
        'INSERT INTO applications (project_id, user_id, message, match_score) VALUES (?, ?, ?, ?)',
        [projectId, req.user.id, message, matchScore],
        function(err) {
          if (err) {
            return res.status(500).json({ error: 'Failed to submit application' });
          }
          res.json({
            id: this.lastID,
            project_id: projectId,
            user_id: req.user.id,
            message,
            match_score: matchScore,
            status: 'pending'
          });
        }
      );
    });
  });
});

app.put('/api/applications/:id/status', authenticateToken, (req, res) => {
  const { status } = req.body;
  
  db.run(
    'UPDATE applications SET status = ? WHERE id = ?',
    [status, req.params.id],
    function(err) {
      if (err) {
        return res.status(500).json({ error: 'Failed to update application' });
      }
      res.json({ success: true });
    }
  );
});

// Contribution routes
app.get('/api/projects/:id/contributions', (req, res) => {
  const query = `
    SELECT c.*, u.name as contributor_name
    FROM contributions c
    JOIN users u ON c.user_id = u.id
    WHERE c.project_id = ?
    ORDER BY c.created_at DESC
  `;
  
  db.all(query, [req.params.id], (err, contributions) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to fetch contributions' });
    }
    res.json(contributions);
  });
});

app.get('/api/users/:id/contributions', (req, res) => {
  const query = `
    SELECT c.*, p.title as project_title
    FROM contributions c
    JOIN projects p ON c.project_id = p.id
    WHERE c.user_id = ?
    ORDER BY c.created_at DESC
  `;
  
  db.all(query, [req.params.id], (err, contributions) => {
    if (err) {
      return res.status(500).json({ error: 'Failed to fetch contributions' });
    }
    res.json(contributions);
  });
});

app.post('/api/projects/:id/contributions', authenticateToken, (req, res) => {
  const { description, points } = req.body;
  const projectId = req.params.id;
  const contributionPoints = points || 10;

  db.run(
    'INSERT INTO contributions (project_id, user_id, description, points) VALUES (?, ?, ?, ?)',
    [projectId, req.user.id, description, contributionPoints],
    function(err) {
      if (err) {
        return res.status(500).json({ error: 'Failed to add contribution' });
      }

      // Update user reputation points
      db.run(
        'UPDATE users SET reputation_points = reputation_points + ? WHERE id = ?',
        [contributionPoints, req.user.id],
        (err) => {
          if (err) {
            console.error('Failed to update reputation:', err);
          }

          // Check for badges
          db.get('SELECT reputation_points, badges FROM users WHERE id = ?',
            [req.user.id],
            (err, user) => {
              if (!err && user) {
                const badges = JSON.parse(user.badges || '[]');
                let updated = false;

                // Award badges based on reputation
                if (user.reputation_points >= 100 && !badges.includes('Contributor')) {
                  badges.push('Contributor');
                  updated = true;
                }
                if (user.reputation_points >= 500 && !badges.includes('Expert')) {
                  badges.push('Expert');
                  updated = true;
                }
                if (user.reputation_points >= 1000 && !badges.includes('Master')) {
                  badges.push('Master');
                  updated = true;
                }

                if (updated) {
                  db.run('UPDATE users SET badges = ? WHERE id = ?',
                    [JSON.stringify(badges), req.user.id]);
                }
              }
            }
          );
        }
      );

      res.json({
        id: this.lastID,
        project_id: projectId,
        user_id: req.user.id,
        description,
        points: contributionPoints
      });
    }
  );
});

// Serve frontend for root path
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../client/public/index.html'));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
