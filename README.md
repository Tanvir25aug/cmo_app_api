# CMO API - Node.js Backend

RESTful API for CMO (Change Meter Owner) mobile application built with Node.js, Express.js, and SQL Server.

## 🚀 Features

- **Authentication**: JWT-based authentication with refresh tokens
- **CMO Management**: Complete CRUD operations for CMO requests
- **File Upload**: Image upload for meters and seals
- **Sync Support**: Bulk sync for offline-first mobile app
- **Security**: Helmet, CORS, input validation
- **Logging**: Winston logger with file and console output
- **Error Handling**: Centralized error handling
- **Database**: SQL Server with Sequelize ORM

## 📋 Prerequisites

- Node.js 18.x or higher
- SQL Server database
- npm or yarn

## 🛠️ Installation

1. **Clone/Navigate to project**
   ```bash
   cd "D:\OTBL Project\cmo-api"
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   # Copy .env.example to .env and update values
   copy .env.example .env
   ```

4. **Update .env file** with your database credentials

## 🚀 Running the Application

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

## 📡 API Endpoints

### Base URL
```
http://localhost:8080/api
```

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/refresh-token` - Refresh access token
- `GET /api/auth/profile` - Get user profile (protected)
- `PUT /api/auth/profile` - Update profile (protected)
- `PUT /api/auth/change-password` - Change password (protected)
- `POST /api/auth/logout` - Logout (protected)

### CMO Requests
- `GET /api/cmo` - Get all CMOs (protected)
- `GET /api/cmo/:id` - Get CMO by ID (protected)
- `POST /api/cmo` - Create new CMO (protected)
- `PUT /api/cmo/:id` - Update CMO (protected)
- `DELETE /api/cmo/:id` - Delete CMO (protected)
- `POST /api/cmo/sync` - Bulk sync CMOs (protected)
- `GET /api/cmo/unsynced` - Get unsynced CMOs (protected)
- `GET /api/cmo/statistics` - Get statistics (protected)

### File Upload
- `POST /api/cmo/:id/upload-meter-image` - Upload meter image
- `POST /api/cmo/:id/upload-seal-image` - Upload seal image

### Health Check
- `GET /api/health` - API health status

## 📝 Request Examples

### Register User
```bash
POST /api/auth/register
Content-Type: application/json

{
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123",
  "fullName": "Test User",
  "phone": "01712345678"
}
```

### Login
```bash
POST /api/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}
```

### Create CMO
```bash
POST /api/cmo
Authorization: Bearer {token}
Content-Type: application/json

{
  "customerName": "John Doe",
  "mobileNumber": "01712345678",
  "email": "john@example.com",
  "customerId": "CUST001",
  "newMeterId": "METER001",
  "oldMeterType": "1P",
  "status": "draft"
}
```

## 🗄️ Database Schema

The API automatically creates the following tables:

- **users** - User accounts
- **cmo_requests** - CMO request records

## 📁 Project Structure

```
cmo-api/
├── src/
│   ├── config/          # Configuration files
│   ├── controllers/     # Request handlers
│   ├── middleware/      # Custom middleware
│   ├── models/          # Database models
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   ├── utils/           # Helper functions
│   └── app.js           # Express app setup
├── uploads/             # Uploaded files
├── logs/                # Application logs
├── .env                 # Environment variables
├── .gitignore
├── package.json
├── ecosystem.config.js  # PM2 configuration
└── server.js            # Entry point
```

## 🔒 Security Features

- JWT authentication
- Password hashing (bcrypt)
- Input validation
- SQL injection protection (Sequelize ORM)
- Helmet.js security headers
- CORS configuration
- File upload validation

## 📊 Logging

Logs are stored in the `logs/` directory:
- `combined.log` - All logs
- `error.log` - Error logs only

## 🚀 Deployment

### Using PM2 (Recommended for Windows Server)

1. **Install PM2 globally**
   ```bash
   npm install -g pm2
   ```

2. **Start application**
   ```bash
   pm2 start ecosystem.config.js
   ```

3. **View logs**
   ```bash
   pm2 logs cmo-api
   ```

4. **Monitor**
   ```bash
   pm2 monit
   ```

5. **Set up as Windows Service**
   ```bash
   npm install -g pm2-windows-service
   pm2-service-install
   ```



## 🧪 Testing

```bash
# Add tests here
npm test
```

## 📝 License

MIT

## 👥 Team

OTBL Development Team

## 📞 Support

For issues or questions, contact the development team.
