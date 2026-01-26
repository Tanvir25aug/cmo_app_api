# CMO API - Deployment Guide for Windows Server with IIS

This guide will help you deploy the CMO API on a Windows Server using IIS (Internet Information Services).

## Table of Contents
- [Prerequisites](#prerequisites)
- [GitHub Setup](#github-setup)
- [Windows Server Setup](#windows-server-setup)
- [IIS Configuration](#iis-configuration)
- [Database Setup](#database-setup)
- [Application Deployment](#application-deployment)
- [Production Configuration](#production-configuration)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### On Your Development Machine:
- Git installed
- GitHub account

### On Windows Server:
- Windows Server 2012 R2 or higher
- IIS 8.0 or higher
- Node.js 18.0.0 or higher
- SQL Server (any edition)
- Administrator access

---

## GitHub Setup

### 1. Create a GitHub Repository

1. Go to https://github.com and log in
2. Click the "+" icon in top right and select "New repository"
3. Enter repository details:
   - **Repository name**: `cmo-api` (or your preferred name)
   - **Description**: "CMO API - Change Meter Owner REST API"
   - **Visibility**: Private (recommended) or Public
   - **Do NOT** initialize with README (we already have one)
4. Click "Create repository"

### 2. Upload Code to GitHub

Open Command Prompt or PowerShell in your project directory and run:

```bash
# Navigate to your project directory
cd "D:\OTBL Project\cmo-api"

# Initialize git repository (if not already done)
git init

# Add all files to staging
git add .

# Create first commit
git commit -m "Initial commit - CMO API"

# Add GitHub remote (replace YOUR_USERNAME and REPO_NAME)
git remote add origin https://github.com/YOUR_USERNAME/cmo-api.git

# Push to GitHub
git branch -M main
git push -u origin main
```

**Note**: Replace `YOUR_USERNAME` with your GitHub username and `cmo-api` with your repository name.

### 3. Verify Upload

- Go to your GitHub repository URL
- You should see all your files uploaded
- The `.env` file will NOT be uploaded (it's in `.gitignore` for security)

---

## Windows Server Setup

### 1. Install Prerequisites

#### A. Install IIS

1. Open **Server Manager**
2. Click **Add roles and features**
3. Select **Web Server (IIS)**
4. Include these features:
   - Web Server
   - Application Development Features
   - CGI
   - ISAPI Extensions
   - ISAPI Filters
5. Complete installation

#### B. Install Node.js

1. Download Node.js from https://nodejs.org (LTS version 18+)
2. Run installer with these options:
   - ✅ Automatically install necessary tools
   - ✅ Add to PATH
3. Verify installation:
   ```cmd
   node --version
   npm --version
   ```

#### C. Install iisnode

1. Download iisnode from: https://github.com/Azure/iisnode/releases
2. Choose the correct version:
   - For x64: `iisnode-full-v0.2.26-x64.msi`
   - For x86: `iisnode-full-v0.2.26-x86.msi`
3. Run installer (default settings)
4. Restart IIS:
   ```cmd
   iisreset
   ```

#### D. Install URL Rewrite Module

1. Download from: https://www.iis.net/downloads/microsoft/url-rewrite
2. Run installer
3. Restart IIS

---

## IIS Configuration

### 1. Clone Repository to Server

On Windows Server, open PowerShell or Command Prompt:

```bash
# Navigate to IIS website directory (example)
cd C:\inetpub\wwwroot

# Clone your repository (replace with your GitHub URL)
git clone https://github.com/YOUR_USERNAME/cmo-api.git

# Navigate to project
cd cmo-api
```

### 2. Install Dependencies

```bash
npm install --production
```

### 3. Create Required Directories

```bash
# Create uploads directory
mkdir uploads

# Create logs directory
mkdir logs

# Create iisnode logs directory
mkdir iisnode
```

### 4. Configure IIS Website

#### Option A: Using IIS Manager (GUI)

1. Open **IIS Manager**
2. Right-click **Sites** → **Add Website**
3. Enter details:
   - **Site name**: `CMO-API`
   - **Physical path**: `C:\inetpub\wwwroot\cmo-api`
   - **Binding**:
     - Type: `http`
     - Port: `8080` (or your preferred port)
     - Host name: (leave blank or enter domain)
4. Click **OK**

5. Configure Application Pool:
   - Select your website
   - Click **Basic Settings** → **Application Pool**
   - Click **Select** → Choose **DefaultAppPool** or create new one
   - Set **Identity** to **ApplicationPoolIdentity** or a specific service account

6. Set Permissions:
   - Right-click site folder → **Edit Permissions**
   - **Security** tab → **Edit**
   - Add **IIS_IUSRS** and **IUSR** with:
     - ✅ Read & Execute
     - ✅ List folder contents
     - ✅ Read
     - ✅ Write (for uploads and logs folders)

#### Option B: Using PowerShell

```powershell
# Import IIS module
Import-Module WebAdministration

# Create website
New-WebSite -Name "CMO-API" `
  -Port 8080 `
  -PhysicalPath "C:\inetpub\wwwroot\cmo-api" `
  -ApplicationPool "DefaultAppPool"

# Set permissions
$path = "C:\inetpub\wwwroot\cmo-api"
icacls $path /grant "IIS_IUSRS:(OI)(CI)RX"
icacls $path /grant "IUSR:(OI)(CI)RX"
icacls "$path\uploads" /grant "IIS_IUSRS:(OI)(CI)M"
icacls "$path\logs" /grant "IIS_IUSRS:(OI)(CI)M"
icacls "$path\iisnode" /grant "IIS_IUSRS:(OI)(CI)M"
```

---

## Database Setup

### 1. Ensure SQL Server is Running

```cmd
# Check SQL Server service status
sc query MSSQLSERVER
```

### 2. Create Database

Run the SQL script to create database and tables:

```bash
# If you have database scripts in the database folder
sqlcmd -S YOUR_SERVER_NAME -U YOUR_USERNAME -P YOUR_PASSWORD -i database\create_database.sql
```

### 3. Configure Database Connection

Create `.env` file based on `.env.example`:

```bash
# Copy example file
copy .env.example .env

# Edit .env file with your actual values
notepad .env
```

Update these values in `.env`:

```env
# Server Configuration
NODE_ENV=production
PORT=8080
HOST=0.0.0.0

# Database Configuration (SQL Server)
DB_SERVER=localhost\SQLEXPRESS
DB_NAME=MeterOCRDESCO
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_PORT=1433

# JWT Configuration
JWT_SECRET=your_production_jwt_secret_here_min_32_chars
JWT_EXPIRE=24h
JWT_REFRESH_EXPIRE=7d

# Upload Configuration
UPLOAD_PATH=./uploads
MAX_FILE_SIZE=10485760

# CORS Configuration
CORS_ORIGIN=*

# API Configuration
API_VERSION=v1
API_PREFIX=/api
```

**Security Note**: Use a strong, random JWT_SECRET in production (minimum 32 characters).

---

## Application Deployment

### 1. Test Application Locally

Before deploying to IIS, test the application:

```bash
# Set environment to production
set NODE_ENV=production

# Test the application
node server.js
```

You should see:
```
🚀 CMO API Server is running on http://0.0.0.0:8080
✅ Database connection has been established successfully.
```

Press `Ctrl+C` to stop.

### 2. Configure Firewall

Allow incoming connections on your API port:

```powershell
# Allow port 8080 (or your chosen port)
New-NetFirewallRule -DisplayName "CMO API" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

### 3. Start IIS Website

```powershell
# Start the website
Start-WebSite -Name "CMO-API"

# Restart IIS to ensure all changes take effect
iisreset
```

### 4. Verify Deployment

Test the API endpoints:

```bash
# Health check (replace localhost with your server IP/domain)
curl http://localhost:8080/api/health

# Expected response:
# {"status":"ok","timestamp":"2025-12-30T..."}
```

---

## Production Configuration

### 1. Environment Variables

Ensure `.env` file has production values:
- ✅ `NODE_ENV=production`
- ✅ Strong `JWT_SECRET`
- ✅ Correct database credentials
- ✅ Appropriate `CORS_ORIGIN` (not `*` in production)

### 2. HTTPS Configuration (Recommended)

For production, you should use HTTPS:

1. Obtain SSL certificate:
   - From a Certificate Authority (CA)
   - Or use Let's Encrypt

2. In IIS Manager:
   - Select your website
   - **Bindings** → **Add**
   - Type: `https`
   - Port: `443`
   - SSL certificate: Select your certificate

### 3. Logging Configuration

Logs are stored in:
- Application logs: `./logs/combined.log` and `./logs/error.log`
- IIS/iisnode logs: `./iisnode/`

Monitor these logs regularly for errors.

### 4. Backup Strategy

Set up regular backups for:
- Database (`MeterOCRDESCO`)
- Uploaded files (`./uploads` directory)
- Configuration files (`.env`)

---

## Troubleshooting

### Common Issues

#### 1. "Cannot GET /" or 404 errors

**Solution**:
- Verify `web.config` exists in project root
- Check IIS URL Rewrite module is installed
- Restart IIS: `iisreset`

#### 2. "Module not found" errors

**Solution**:
```bash
# Reinstall dependencies
npm install --production
```

#### 3. Database connection errors

**Solution**:
- Verify SQL Server is running
- Check `.env` database credentials
- Test connection manually:
  ```bash
  sqlcmd -S YOUR_SERVER -U YOUR_USER -P YOUR_PASSWORD
  ```
- Ensure SQL Server allows remote connections
- Check firewall allows SQL Server port (1433)

#### 4. Permission denied errors

**Solution**:
```powershell
# Grant IIS users full access to necessary folders
$path = "C:\inetpub\wwwroot\cmo-api"
icacls "$path\uploads" /grant "IIS_IUSRS:(OI)(CI)F"
icacls "$path\logs" /grant "IIS_IUSRS:(OI)(CI)F"
icacls "$path\iisnode" /grant "IIS_IUSRS:(OI)(CI)F"
```

#### 5. Application crashes or restarts

**Check logs**:
```bash
# View error log
type logs\error.log

# View iisnode logs
type iisnode\*-stderr-*.txt
```

#### 6. Port already in use

**Solution**:
```bash
# Find process using port 8080
netstat -ano | findstr :8080

# Kill process (replace PID with actual process ID)
taskkill /PID <PID> /F
```

### Viewing Logs

```bash
# Application logs
type logs\combined.log
type logs\error.log

# IIS/iisnode logs
type iisnode\*.txt
```

---

## Maintenance

### Updating the Application

1. **Backup current version**:
   ```bash
   cd C:\inetpub\wwwroot
   xcopy /E /I cmo-api cmo-api-backup
   ```

2. **Pull latest changes**:
   ```bash
   cd cmo-api
   git pull origin main
   ```

3. **Install new dependencies**:
   ```bash
   npm install --production
   ```

4. **Restart IIS**:
   ```bash
   iisreset
   ```

### Monitoring

- Monitor IIS logs regularly
- Check application logs in `./logs/`
- Monitor SQL Server performance
- Check disk space for `uploads` folder

---

## Alternative: PM2 Instead of IIS

If you prefer using PM2 (Process Manager) instead of IIS:

### Install PM2 globally:
```bash
npm install -g pm2
```

### Start application:
```bash
pm2 start ecosystem.config.js --env production
```

### Configure PM2 as Windows Service:
```bash
npm install -g pm2-windows-service
pm2-service-install
```

### Manage PM2:
```bash
pm2 status              # Check status
pm2 logs                # View logs
pm2 restart cmo-api     # Restart app
pm2 stop cmo-api        # Stop app
```

---

## Support

For issues or questions:
- Check the [Troubleshooting](#troubleshooting) section
- Review application logs
- Contact your development team

---

## Security Checklist

Before going live:
- [ ] `.env` file is not in version control
- [ ] Strong JWT_SECRET is set
- [ ] Database credentials are secure
- [ ] CORS_ORIGIN is set to specific domain (not `*`)
- [ ] HTTPS is configured
- [ ] Firewall rules are configured
- [ ] SQL Server has proper authentication
- [ ] File upload limits are set
- [ ] Regular backups are scheduled
- [ ] Monitoring is in place

---

**Last Updated**: 2025-12-30
**Version**: 1.0.0
