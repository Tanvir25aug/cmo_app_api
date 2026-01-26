# Update Production Script for CMO API
# This script pulls the latest changes from GitHub and restarts the application
# Run as Administrator

param(
    [string]$DeploymentMethod = "PM2",  # Options: "PM2" or "IIS"
    [string]$ProjectPath = "C:\inetpub\wwwroot\cmo-api",
    [switch]$SkipBackup = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CMO API - Production Update Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator. Some operations may fail." -ForegroundColor Yellow
    Write-Host "Consider running PowerShell as Administrator." -ForegroundColor Yellow
    Write-Host ""
}

# Navigate to project directory
Write-Host "Step 1: Navigating to project directory..." -ForegroundColor Green
if (Test-Path $ProjectPath) {
    Set-Location $ProjectPath
    Write-Host "✓ Current directory: $ProjectPath" -ForegroundColor Green
} else {
    Write-Host "✗ Error: Project path not found: $ProjectPath" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Backup .env file
Write-Host "Step 2: Backing up .env file..." -ForegroundColor Green
if (Test-Path ".env") {
    if (-not $SkipBackup) {
        Copy-Item .env .env.backup -Force
        Write-Host "✓ .env backed up to .env.backup" -ForegroundColor Green
    } else {
        Write-Host "⊙ Backup skipped" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Warning: .env file not found" -ForegroundColor Yellow
}
Write-Host ""

# Stop application
Write-Host "Step 3: Stopping application..." -ForegroundColor Green
if ($DeploymentMethod -eq "PM2") {
    Write-Host "Using PM2 deployment method..." -ForegroundColor Cyan
    try {
        pm2 stop cmo-api 2>&1 | Out-Null
        Write-Host "✓ PM2 application stopped" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Warning: Could not stop PM2 application (may not be running)" -ForegroundColor Yellow
    }
} elseif ($DeploymentMethod -eq "IIS") {
    Write-Host "Using IIS deployment method..." -ForegroundColor Cyan
    try {
        Import-Module WebAdministration -ErrorAction SilentlyContinue
        Stop-WebSite -Name "CMO-API" -ErrorAction SilentlyContinue
        Write-Host "✓ IIS website stopped" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Warning: Could not stop IIS website" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Error: Invalid deployment method: $DeploymentMethod" -ForegroundColor Red
    Write-Host "Valid options: PM2 or IIS" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Pull latest changes from GitHub
Write-Host "Step 4: Pulling latest changes from GitHub..." -ForegroundColor Green
try {
    # Check if git is available
    $gitVersion = git --version 2>&1
    Write-Host "Git version: $gitVersion" -ForegroundColor Cyan

    # Pull changes
    Write-Host "Running: git pull origin main" -ForegroundColor Cyan
    $pullOutput = git pull origin main 2>&1
    Write-Host $pullOutput -ForegroundColor White

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Successfully pulled latest changes" -ForegroundColor Green
    } else {
        Write-Host "✗ Error: Git pull failed" -ForegroundColor Red
        Write-Host "Please resolve git issues manually" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Error: Git is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Git or update manually" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Install dependencies
Write-Host "Step 5: Installing dependencies..." -ForegroundColor Green
try {
    Write-Host "Running: npm install --production" -ForegroundColor Cyan
    $npmOutput = npm install --production 2>&1
    Write-Host $npmOutput -ForegroundColor White

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Dependencies installed successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Error: npm install failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Error: npm is not installed or not in PATH" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Start application
Write-Host "Step 6: Starting application..." -ForegroundColor Green
if ($DeploymentMethod -eq "PM2") {
    try {
        pm2 start cmo-api 2>&1 | Out-Null
        Write-Host "✓ PM2 application started" -ForegroundColor Green
        Write-Host ""
        Write-Host "Checking PM2 status..." -ForegroundColor Cyan
        pm2 status
    } catch {
        Write-Host "✗ Error: Could not start PM2 application" -ForegroundColor Red
        exit 1
    }
} elseif ($DeploymentMethod -eq "IIS") {
    try {
        # Touch web.config to restart iisnode
        (Get-Item web.config).LastWriteTime = Get-Date
        Write-Host "✓ web.config touched (triggers iisnode restart)" -ForegroundColor Green

        # Start IIS website
        Start-WebSite -Name "CMO-API" -ErrorAction SilentlyContinue
        Write-Host "✓ IIS website started" -ForegroundColor Green

        # Alternative: Full IIS reset (commented out - use if needed)
        # Write-Host "Running: iisreset" -ForegroundColor Cyan
        # iisreset

    } catch {
        Write-Host "✗ Error: Could not start IIS website" -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Test the API
Write-Host "Step 7: Testing API..." -ForegroundColor Green
Start-Sleep -Seconds 3  # Wait for application to start
try {
    Write-Host "Testing: http://localhost:8085/api/health" -ForegroundColor Cyan
    $response = Invoke-WebRequest -Uri "http://localhost:8085/api/health" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ API is responding correctly!" -ForegroundColor Green
        Write-Host "Response: $($response.Content)" -ForegroundColor White
    } else {
        Write-Host "⚠ Warning: API responded with status code: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Warning: Could not test API (may still be starting)" -ForegroundColor Yellow
    Write-Host "Error: $_" -ForegroundColor Yellow
    Write-Host "Please check manually: http://localhost:8085/api/health" -ForegroundColor Cyan
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Update Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API should be available at: http://localhost:8085/api/health" -ForegroundColor Cyan
Write-Host ""
if ($DeploymentMethod -eq "PM2") {
    Write-Host "To view logs: pm2 logs cmo-api" -ForegroundColor Cyan
    Write-Host "To check status: pm2 status" -ForegroundColor Cyan
} elseif ($DeploymentMethod -eq "IIS") {
    Write-Host "To check IIS logs: Check iisnode\ folder" -ForegroundColor Cyan
    Write-Host "To restart IIS: iisreset" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Deployment completed successfully! ✓" -ForegroundColor Green
