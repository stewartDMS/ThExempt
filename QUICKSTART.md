# ThExempt - Quick Start Guide

## Overview
ThExempt is a social network that connects ambitious young men to real-world business projects. Users can discover opportunities, contribute their skills, and build their reputation while helping businesses succeed.

## Prerequisites
- Node.js (v14 or higher)
- npm (v6 or higher)

## Quick Start

### 1. Installation
```bash
# Clone the repository
git clone https://github.com/stewartDMS/ThExempt.git
cd ThExempt

# Install dependencies
npm install
```

### 2. Configuration
Create a `.env` file in the root directory:
```env
PORT=5000
JWT_SECRET=your-secure-random-secret-key-at-least-32-characters-long
NODE_ENV=development
```

**Important:** Generate a strong JWT_SECRET for security. You can use:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 3. Start the Server
```bash
npm start
```

The server will start on http://localhost:5000

### 4. Access the Application
Open your browser and navigate to:
```
http://localhost:5000
```

## First Steps

### For Users
1. **Sign Up**: Create an account by clicking "Sign Up"
2. **Browse Projects**: View available business opportunities
3. **Apply**: Submit applications to projects that interest you
4. **Contribute**: Log your work contributions
5. **Build Reputation**: Earn points and badges for your contributions

### For Business Owners
1. **Sign Up**: Create an account
2. **Post Project**: Click "Post Project" to create a new opportunity
3. **Review Applications**: See who applied with their match scores
4. **Track Progress**: Monitor team contributions

## Key Features

### 🔐 Secure Authentication
- JWT-based authentication
- Encrypted passwords (bcrypt)
- Rate-limited login attempts

### 📋 Project Management
- Post and browse projects
- Required skills matching
- Application system

### 📊 Contribution Tracking
- Log your work
- Build contribution history
- Track progress visually

### 🏆 Reputation System
- Earn 10 points per contribution
- Unlock badges:
  - Contributor (100+ points)
  - Expert (500+ points)
  - Master (1000+ points)

### 🤖 Smart Matching
- AI-assisted project matching
- Skill compatibility scoring
- Find best-fit opportunities

## Architecture

```
ThExempt/
├── server/
│   └── index.js          # Express server with all API endpoints
├── client/
│   └── public/
│       └── index.html    # Single-page application
├── package.json          # Dependencies and scripts
├── .env                  # Environment variables (create this)
└── README.md             # Full documentation
```

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Create account
- `POST /api/auth/login` - Login

### Projects
- `GET /api/projects` - List all projects
- `POST /api/projects` - Create project
- `POST /api/projects/:id/apply` - Apply to project

### Contributions
- `GET /api/users/:id/contributions` - Get user contributions
- `POST /api/projects/:id/contributions` - Log contribution

### Users
- `GET /api/users/me` - Get current user profile

## Database

The application uses SQLite for simplicity. The database file `thexempt.db` is created automatically on first run.

### Tables:
- `users` - User accounts and reputation
- `projects` - Business projects
- `applications` - Project applications
- `contributions` - User contributions
- `user_skills` - User skill profiles

## Security Notes

⚠️ **Important for Production:**
1. Use a strong, random JWT_SECRET (minimum 32 characters)
2. Enable HTTPS
3. Use PostgreSQL or MySQL instead of SQLite
4. Implement additional security headers
5. Set up proper CORS configuration
6. Regular security audits

## Troubleshooting

### Server won't start
- Check if JWT_SECRET is set in .env file
- Ensure port 5000 is not in use
- Verify Node.js version (14+)

### Can't login
- Clear browser localStorage
- Check server console for errors
- Verify database file exists

### Rate limit errors
- Wait 15 minutes or restart server
- Default: 5 auth attempts per 15 minutes
- Default: 100 API calls per 15 minutes

## Getting Help

- Check the full [README.md](README.md) for detailed documentation
- Review server logs for error messages
- Ensure all environment variables are set correctly

## License
ISC

---

Built with ❤️ for ambitious entrepreneurs
