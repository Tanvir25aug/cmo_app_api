# CMO API Deployment Script for IIS Server
# Target Server: 192.168.10.100
# Run this script as Administrator

param(
    [string]$TargetServer = "192.168.10.100",
    [string]$DeployPath = "D:\Node_API\comAppApiNode",
    [string]$SiteName = "CMO-API",
    [int]$Port = 8085
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CMO API IIS Deployment Script" -ForegroundColor Cyan
Write-Host "  Target Server: $TargetServer" -ForegroundColor Cyan
Write-Host "  Deploy Path: $DeployPath" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Copy files to server
Write-Host "[Step 1] Copying files to server..." -ForegroundColor Yellow

$SourcePath = Split-Path -Parent $MyInvocation.MyCommand.Path
$RemotePath = "\\$TargetServer\D$\Node_API\comAppApiNode"

# Create list of files/folders to exclude
$ExcludeItems = @(
    "node_modules",
    ".git",
    "*.log",
    "iisnode",
    "deploy-to-server.ps1"
)

try {
    # Create destination folder if it doesn't exist
    if (!(Test-Path $RemotePath)) {
        New-Item -ItemType Directory -Path $RemotePath -Force | Out-Null
        Write-Host "  Created directory: $RemotePath" -ForegroundColor Green
    }

    # Copy files using robocopy (better for large copies)
    Write-Host "  Copying files..." -ForegroundColor Gray
    robocopy $SourcePath $RemotePath /E /MIR /XD node_modules .git iisnode logs /XF *.log deploy-to-server.ps1 .env

    Write-Host "  Files copied successfully!" -ForegroundColor Green
} catch {
    Write-Host "  Error copying files: $_" -ForegroundColor Red
    Write-Host "  Make sure you have network access to $TargetServer" -ForegroundColor Yellow
    exit 1
}

# Step 2: Create production .env file on server
Write-Host ""
Write-Host "[Step 2] Creating production .env file..." -ForegroundColor Yellow

$EnvContent = @"
# Production Environment Configuration
# Server: $TargetServer

# Server Configuration
NODE_ENV=production
PORT=$Port
HOST=0.0.0.0

# Database Configuration (SQL Server)
DB_SERVER=192.168.10.104
DB_NAME=MeterOCRDESCO
DB_USER=sa
DB_PASSWORD=sqlbis@^7*
DB_PORT=1433

# JWT Configuration
JWT_SECRET=ByYM000OLlMQG6VVVp1OH7Xzyr7gHuw1qvUC5dcGt3SNM
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
"@

try {
    $EnvContent | Out-File -FilePath "$RemotePath\.env" -Encoding utf8 -Force
    Write-Host "  .env file created successfully!" -ForegroundColor Green
} catch {
    Write-Host "  Error creating .env file: $_" -ForegroundColor Red
}

# Step 3: Create required directories
Write-Host ""
Write-Host "[Step 3] Creating required directories..." -ForegroundColor Yellow

$Directories = @("uploads", "logs", "iisnode")
foreach ($dir in $Directories) {
    $dirPath = "$RemotePath\$dir"
    if (!(Test-Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Exists: $dir" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Files copied to $TargetServer" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS (Run on $TargetServer):" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Connect to server via RDP:" -ForegroundColor Cyan
Write-Host "   mstsc /v:$TargetServer" -ForegroundColor White
Write-Host ""
Write-Host "2. Open PowerShell as Administrator and run:" -ForegroundColor Cyan
Write-Host "   cd $DeployPath" -ForegroundColor White
Write-Host "   npm install --production" -ForegroundColor White
Write-Host ""
Write-Host "3. Configure IIS (if not already done):" -ForegroundColor Cyan
Write-Host "   - Run the IIS setup script: .\setup-iis.ps1" -ForegroundColor White
Write-Host ""
Write-Host "4. Test the API:" -ForegroundColor Cyan
Write-Host "   curl http://localhost:$Port/api/health" -ForegroundColor White
Write-Host ""
