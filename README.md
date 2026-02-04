# ThExempt

A social network for ambitious young men to discover purpose, implement and build skills, and ownership by contributing to real business ideas that they help build, launch, and scale.

## Features

### ✨ Core MVP Features Implemented

- **🔐 Sign-in/Sign-up Pages** - Secure authentication with JWT tokens and bcrypt password hashing
- **📋 Project Posting & Application** - Businesses can post projects, users can apply with personalized messages
- **📊 Contribution Tracking** - Log contributions to projects and track your work history
- **🏆 Reputation Points & Badges** - Earn reputation points for contributions and unlock achievement badges
  - Contributor badge (100+ points)
  - Expert badge (500+ points)
  - Master badge (1000+ points)
- **🤖 AI-Assisted Matching** - Basic rule engine calculates match scores based on user skills vs. project requirements

### 🎨 Modern UI/UX Design

The interface features a modern, sleek design that conveys:
- **Unity** - Connected community through collaboration
- **Strength** - Bold colors and confident typography
- **Progress** - Visual feedback on reputation and contributions

## Tech Stack

- **Frontend**: Vanilla JavaScript, HTML5, CSS3
- **Backend**: Node.js, Express.js
- **Database**: SQLite3
- **Authentication**: JWT, bcryptjs
- **Security**: Rate limiting, input validation

## Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: Bcrypt with salt rounds for secure password storage
- **Rate Limiting**: 
  - Auth routes: 5 requests per 15 minutes per IP
  - API routes: 100 requests per 15 minutes per IP
- **Environment Variables**: Sensitive data stored in .env file
- **Input Validation**: Server-side validation for all user inputs
- **CORS**: Configured for controlled cross-origin access

## Installation

1. Clone the repository:
```bash
git clone https://github.com/stewartDMS/ThExempt.git
cd ThExempt
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file with required environment variables:
```env
PORT=5000
JWT_SECRET=your-secure-random-secret-key-at-least-32-characters-long
NODE_ENV=development
```

**Important Security Note:** 
- Never commit your `.env` file to version control
- Generate a strong, random JWT_SECRET (minimum 32 characters)
- Change the JWT_SECRET in production environments

4. Start the server:
```bash
npm start
```

5. Open your browser and navigate to:
```
http://localhost:5000
```

## Usage

### For New Users

1. **Sign Up**: Click "Sign Up" and create an account with your name, email, and password
2. **Browse Projects**: View available projects on your dashboard
3. **Apply to Projects**: Click "Apply" on projects that interest you
4. **Log Contributions**: Track your work by logging contributions to projects
5. **Earn Reputation**: Build your reputation by making meaningful contributions

### For Project Owners

1. **Post a Project**: Click "Post Project" to create a new business opportunity
2. **Add Details**: Provide a title, description, and list required skills
3. **Review Applications**: See applicants with their match scores
4. **Track Progress**: Monitor contributions from team members

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Create a new user account
- `POST /api/auth/login` - Login with email and password

### Users
- `GET /api/users/me` - Get current user profile
- `GET /api/users/:id/skills` - Get user's skills
- `POST /api/users/skills` - Add a new skill
- `GET /api/users/:id/contributions` - Get user's contributions

### Projects
- `GET /api/projects` - List all open projects
- `GET /api/projects/:id` - Get project details
- `POST /api/projects` - Create a new project
- `GET /api/projects/:id/applications` - Get project applications
- `POST /api/projects/:id/apply` - Apply to a project
- `GET /api/projects/:id/contributions` - Get project contributions
- `POST /api/projects/:id/contributions` - Log a contribution

## Database Schema

### Users
- `id`, `email`, `password`, `name`, `role`, `reputation_points`, `badges`, `created_at`

### Projects
- `id`, `title`, `description`, `owner_id`, `status`, `required_skills`, `created_at`

### Applications
- `id`, `project_id`, `user_id`, `status`, `message`, `match_score`, `created_at`

### Contributions
- `id`, `project_id`, `user_id`, `description`, `points`, `created_at`

### User Skills
- `id`, `user_id`, `skill`, `proficiency`

## AI-Assisted Matching

The matching algorithm compares user skills with project requirements:
- Calculates percentage of matching skills
- Displays match score when applying to projects
- Helps project owners identify qualified candidates

## Future Enhancements

- Advanced ML-based matching algorithm
- Real-time messaging between team members
- Video conferencing integration
- Portfolio showcase for users
- Project milestones and deadlines
- Payment integration for project rewards
- Mobile app (React Native)
- Enhanced rate limiting per user/route
- Two-factor authentication
- OAuth integration (Google, GitHub)

## Production Deployment Notes

Before deploying to production:

1. **Set strong JWT_SECRET**: Generate a cryptographically secure random string (minimum 32 characters)
2. **Use HTTPS**: Always use SSL/TLS in production
3. **Database**: Migrate to PostgreSQL or MySQL for production use
4. **Environment Variables**: Never commit .env files; use secure secret management
5. **Rate Limiting**: Adjust rate limits based on your traffic patterns
6. **Monitoring**: Implement logging and monitoring (e.g., Winston, Sentry)
7. **Backups**: Set up automated database backups
8. **Security Headers**: Add helmet.js for security headers
9. **Input Sanitization**: Add additional input sanitization for XSS prevention
10. **CORS**: Configure CORS for your specific domain only

## License

ISC

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
