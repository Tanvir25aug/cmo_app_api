# CMO API - Deployment Guide for Windows Server

## 📋 Prerequisites

### Software Requirements
- Windows Server 2016/2019/2022
- Node.js 18.x LTS or higher
- SQL Server database access
- npm (comes with Node.js)
- PM2 (for process management)

### System Requirements
- RAM: 4GB minimum (8GB recommended)
- Disk: 10GB free space
- Network: Access to SQL Server (192.168.10.104:1433)

---

## 🚀 Step-by-Step Deployment

### Step 1: Install Node.js

1. **Download Node.js**
   - Visit: https://nodejs.org/en/download
   - Download: Windows Installer (.msi) - 64-bit
   - Version: 18.x LTS (Long Term Support)

2. **Install Node.js**
   ```powershell
   # Run the downloaded installer
   # Accept all default options
   # Make sure "Add to PATH" is checked
   ```

3. **Verify Installation**
   ```powershell
   node --version
   # Should show: v18.x.x

   npm --version
   # Should show: 9.x.x or higher
   ```

### Step 2: Copy Project Files

1. **Copy the entire `cmo-api` folder to server**
   ```
   Recommended location: C:\inetpub\wwwroot\cmo-api\
   or
   D:\Applications\cmo-api\
   ```

2. **Navigate to project directory**
   ```powershell
   cd C:\inetpub\wwwroot\cmo-api
   ```

### Step 3: Configure Environment

1. **Edit `.env` file**
   ```powershell
   notepad .env
   ```

2. **Update with production values**
   ```env
   NODE_ENV=production
   PORT=8085
   HOST=0.0.0.0

   DB_SERVER=192.168.10.104
   DB_NAME=MeterOCRDESCO
   DB_USER=rdpdc
   DB_PASSWORD=Oculin@123
   DB_PORT=1433

   JWT_SECRET=ByYM000OLlMQG6VVVp1OH7Xzyr7gHuw1qvUC5dcGt3SNM
   JWT_EXPIRE=24h
   JWT_REFRESH_EXPIRE=7d

   CORS_ORIGIN=*
   ```

### Step 4: Install Dependencies

```powershell
# Install project dependencies
npm install

# Wait for installation to complete (may take 2-3 minutes)
```

### Step 5: Test Database Connection

```powershell
# Start the server in test mode
npm start
```

**Expected Output:**
```
✅ Database connection established successfully.
📊 Connected to: MeterOCRDESCO on 192.168.10.104
✅ Database synchronized successfully.
🚀 CMO API Server Started
```

**If you see errors:**
- Check database credentials in `.env`
- Verify SQL Server is accessible from this machine
- Check firewall rules

Press `Ctrl+C` to stop the test server.

---

## 🔧 Production Setup with PM2

### Step 1: Install PM2

```powershell
# Install PM2 globally
npm install -g pm2
```

### Step 2: Start Application with PM2

```powershell
# Start the API
pm2 start ecosystem.config.js

# Verify it's running
pm2 status

# View logs
pm2 logs cmo-api

# Monitor performance
pm2 monit
```

### Step 3: Configure PM2 as Windows Service

```powershell
# Install PM2 as Windows Service
npm install -g pm2-windows-service

# Install the service
pm2-service-install

# Service will be named: PM2

# Save current PM2 processes
pm2 save

# The service will auto-start on Windows boot
```

### Step 4: Manage PM2 Service

```powershell
# Start PM2 service
pm2-service-start

# Stop PM2 service
pm2-service-stop

# Restart PM2 service
pm2-service-restart

# Check service status
sc query PM2
```

---

## 🌐 Alternative: IIS Deployment with iisnode

### What is iisnode?
iisnode is a native IIS module that allows hosting Node.js applications in IIS, providing better Windows integration, SSL support, and management through IIS Manager.

### Step 1: Install Prerequisites

1. **Install IIS with required features**
   ```powershell
   # Run as Administrator
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-Performance
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing
   Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic
   ```

2. **Install URL Rewrite Module**
   - Download: https://www.iis.net/downloads/microsoft/url-rewrite
   - Run installer: `rewrite_amd64_en-US.msi`

3. **Install iisnode**
   - Download: https://github.com/Azure/iisnode/releases
   - Install: `iisnode-full-v0.2.21-x64.msi` (or latest version)
   - Restart IIS: `iisreset`

### Step 2: Create web.config

Create `web.config` in your project root (if it doesn't exist):

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>

    <!-- iisnode configuration -->
    <iisnode
      nodeProcessCommandLine="&quot;C:\Program Files\nodejs\node.exe&quot;"
      loggingEnabled="true"
      logDirectory="iisnode"
      debuggingEnabled="false"
      node_env="production"
      />

    <!-- URL Rewrite rules -->
    <rewrite>
      <rules>
        <!-- Don't interfere with iisnode debug requests -->
        <rule name="LogFile" patternSyntax="ECMAScript" stopProcessing="true">
          <match url="^[a-zA-Z0-9_\-]+\.js\.logs\/\d+\.txt$"/>
        </rule>

        <!-- Don't interfere with iisnode inspector -->
        <rule name="NodeInspector" patternSyntax="ECMAScript" stopProcessing="true">
          <match url="^server.js\/debug[\/]?"/>
        </rule>

        <!-- Route all other requests to Node.js -->
        <rule name="StaticContent">
          <action type="Rewrite" url="public{REQUEST_URI}"/>
        </rule>

        <!-- All other URLs are mapped to the Node.js application entry point -->
        <rule name="DynamicContent">
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="True"/>
          </conditions>
          <action type="Rewrite" url="server.js"/>
        </rule>
      </rules>
    </rewrite>

    <!-- Security settings -->
    <security>
      <requestFiltering>
        <hiddenSegments>
          <add segment="node_modules"/>
          <add segment=".env"/>
          <add segment="iisnode"/>
        </hiddenSegments>
      </requestFiltering>
    </security>

    <!-- HTTP Errors -->
    <httpErrors existingResponse="PassThrough"/>

  </system.webServer>
</configuration>
```

### Step 3: Configure IIS Site

1. **Open IIS Manager**
   ```powershell
   inetmgr
   ```

2. **Create new website**
   - Right-click "Sites" → "Add Website"
   - Site name: `CMO-API`
   - Physical path: `C:\inetpub\wwwroot\cmo-api`
   - Port: `8085`
   - Click OK

3. **Configure Application Pool**
   - Go to "Application Pools"
   - Find "CMO-API" pool
   - Right-click → "Advanced Settings"
   - Set ".NET CLR Version": `No Managed Code`
   - Set "Identity": `ApplicationPoolIdentity`
   - Click OK

4. **Set folder permissions**
   ```powershell
   # Grant IIS_IUSRS full access
   icacls "C:\inetpub\wwwroot\cmo-api" /grant "IIS_IUSRS:(OI)(CI)F" /T
   icacls "C:\inetpub\wwwroot\cmo-api\uploads" /grant "IIS_IUSRS:(OI)(CI)F" /T
   icacls "C:\inetpub\wwwroot\cmo-api\logs" /grant "IIS_IUSRS:(OI)(CI)F" /T

   # Grant IUSR read access
   icacls "C:\inetpub\wwwroot\cmo-api" /grant "IUSR:(OI)(CI)R" /T
   ```

### Step 4: Test IIS Deployment

1. **Restart IIS**
   ```powershell
   iisreset
   ```

2. **Test locally**
   ```powershell
   curl http://localhost:8085/api/health
   ```

3. **Check iisnode logs** (if errors occur)
   - Location: `C:\inetpub\wwwroot\cmo-api\iisnode\`

### IIS Management Commands

```powershell
# Restart IIS
iisreset

# Start/Stop specific site
Import-Module WebAdministration
Stop-WebSite -Name "CMO-API"
Start-WebSite -Name "CMO-API"

# Restart Application Pool
Restart-WebAppPool -Name "CMO-API"

# View site status
Get-WebSite -Name "CMO-API"

# View application pool status
Get-WebAppPoolState -Name "CMO-API"
```

### IIS Troubleshooting

**Issue: 500.19 Error - Cannot read configuration file**
- Solution: Ensure web.config is valid XML
- Check file permissions on web.config

**Issue: 502.2 Bad Gateway**
- Check iisnode logs in `iisnode\` folder
- Verify Node.js path in web.config
- Ensure node.exe is accessible

**Issue: Application won't start**
- Test manually: `node server.js`
- Check .env file exists and is configured
- Review iisnode logs
- Check Windows Event Viewer → Application logs

---

## 🔥 Firewall Configuration

### Open Port 8085

```powershell
# Open PowerShell as Administrator

# Add firewall rule
New-NetFirewallRule -DisplayName "CMO API" -Direction Inbound -LocalPort 8085 -Protocol TCP -Action Allow

# Verify rule
Get-NetFirewallRule -DisplayName "CMO API"
```

---

## 🧪 Testing the Deployment

### Test Locally on Server

```powershell
# Test API health
curl http://localhost:8085/api/health

# Expected response:
# {"success":true,"message":"CMO API is running",...}
```

### Test from Network

```powershell
# From another machine on the network
curl http://YOUR_SERVER_IP:8085/api/health
```

### Test with Postman

1. **Create a new request**
   - Method: GET
   - URL: `http://YOUR_SERVER_IP:8085/api/health`

2. **Send request**
   - Should receive success response

---

## 📊 Monitoring & Logs

### View Logs

```powershell
# View real-time logs
pm2 logs cmo-api

# View error logs only
pm2 logs cmo-api --err

# Clear logs
pm2 flush
```

### Log Files Location

```
logs/
├── combined.log       # All logs
├── error.log          # Error logs only
├── pm2-error.log      # PM2 error logs
├── pm2-out.log        # PM2 output logs
└── pm2-combined.log   # PM2 combined logs
```

### Monitor Performance

```powershell
# Real-time monitoring
pm2 monit

# Process information
pm2 info cmo-api

# Show process list
pm2 ls
```

---

## 🔄 Updates & Maintenance

### Update Production from GitHub

#### Method 1: Using Git (Recommended)

```powershell
# Navigate to project directory
cd C:\inetpub\wwwroot\cmo-api

# Backup current .env file
Copy-Item .env .env.backup

# Pull latest changes from GitHub
git pull origin main

# Install any new dependencies
npm install --production

# Restore .env (git won't overwrite it, but just to be safe)
# .env is in .gitignore so your production secrets are safe

# If using PM2: Restart the application
pm2 restart cmo-api

# If using IIS: Restart IIS or just touch web.config
iisreset
# OR
(Get-Item web.config).LastWriteTime = Get-Date  # This restarts iisnode
```

#### Method 2: Manual File Copy

```powershell
# Stop the application first
# For PM2:
pm2 stop cmo-api

# For IIS:
Stop-WebSite -Name "CMO-API"

# Backup current files
Copy-Item -Path "C:\inetpub\wwwroot\cmo-api" -Destination "C:\inetpub\wwwroot\cmo-api-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Recurse

# Copy new files (excluding node_modules and .env)
# Then reinstall dependencies
cd C:\inetpub\wwwroot\cmo-api
npm install --production

# Start the application
# For PM2:
pm2 start cmo-api

# For IIS:
Start-WebSite -Name "CMO-API"
```

### Update Application (Legacy Instructions)

```powershell
# Stop PM2 process
pm2 stop cmo-api

# Pull/copy new code

# Install new dependencies (if any)
npm install

# Restart PM2 process
pm2 restart cmo-api

# Or reload for zero-downtime
pm2 reload cmo-api
```

### Backup Database

```sql
-- Create backup of MeterOCRDESCO database
BACKUP DATABASE MeterOCRDESCO
TO DISK = 'C:\Backup\MeterOCRDESCO.bak'
WITH FORMAT, MEDIANAME = 'CMO_Backup';
```

---

## 🐛 Troubleshooting

### Issue: Port 8085 Already in Use

```powershell
# Find what's using port 8085
netstat -ano | findstr :8085

# Kill the process (use PID from above)
taskkill /PID <PID> /F

# Or change port in .env file
```

### Issue: Database Connection Failed

1. **Check SQL Server is running**
   ```sql
   # In SQL Server Management Studio
   SELECT @@VERSION;
   ```

2. **Check credentials**
   - Verify DB_USER and DB_PASSWORD in `.env`

3. **Check network access**
   ```powershell
   # Test connection to SQL Server
   Test-NetConnection -ComputerName 192.168.10.104 -Port 1433
   ```

4. **Check SQL Server allows remote connections**
   - SQL Server Configuration Manager
   - Enable TCP/IP protocol
   - Restart SQL Server service

### Issue: PM2 Service Not Starting

```powershell
# Uninstall service
pm2-service-uninstall

# Reinstall
pm2-service-install

# Save processes
pm2 save
```

### Issue: High Memory Usage

```powershell
# Set memory limit
pm2 start ecosystem.config.js --max-memory-restart 1G

# Or edit ecosystem.config.js
# max_memory_restart: '1G'
```

---

## 🔒 Security Checklist

- [ ] Change JWT_SECRET to a strong random value
- [ ] Use strong database password
- [ ] Enable HTTPS (add SSL certificate)
- [ ] Configure CORS_ORIGIN to specific domains
- [ ] Enable Windows Firewall
- [ ] Keep Node.js updated
- [ ] Regular database backups
- [ ] Monitor logs for suspicious activity
- [ ] Use environment-specific configurations
- [ ] Disable unnecessary Windows services

---

## 📱 Integration with Flutter App

### Update Flutter App Configuration

In your Flutter app, update the API base URL:

```dart
// lib/utils/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://YOUR_SERVER_IP:8085';
  static const String apiPrefix = '/api';

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String cmoList = '/cmo';
  static const String cmoSync = '/cmo/sync';
}
```

---

## 📞 Support

For issues:
1. Check logs: `pm2 logs cmo-api`
2. Check database connection
3. Verify firewall settings
4. Contact development team

---

## ✅ Deployment Checklist

- [ ] Node.js installed and verified
- [ ] Project files copied to server
- [ ] `.env` configured with production values
- [ ] Dependencies installed (`npm install`)
- [ ] Database connection tested
- [ ] PM2 installed globally
- [ ] Application started with PM2
- [ ] PM2 configured as Windows service
- [ ] Firewall port 8085 opened
- [ ] API tested locally and remotely
- [ ] Logs verified and monitored
- [ ] Flutter app configured with server IP
- [ ] End-to-end testing completed

---

**Deployment Date**: _____________
**Deployed By**: _____________
**Server IP**: _____________
**Version**: 1.0.0
