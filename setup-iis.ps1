# IIS Setup Script for CMO API
# Run this script on the target server (192.168.10.100) as Administrator

param(
    [string]$SiteName = "CMO-API",
    [string]$SitePath = "D:\Node_API\comAppApiNode",
    [int]$Port = 8085
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CMO API - IIS Configuration Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# Step 1: Check prerequisites
Write-Host "[Step 1] Checking prerequisites..." -ForegroundColor Yellow

# Check Node.js
$nodeVersion = node --version 2>$null
if ($nodeVersion) {
    Write-Host "  Node.js: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "  Node.js: NOT INSTALLED" -ForegroundColor Red
    Write-Host "  Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Check IIS
$iisService = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
if ($iisService) {
    Write-Host "  IIS: Installed ($($iisService.Status))" -ForegroundColor Green
} else {
    Write-Host "  IIS: NOT INSTALLED" -ForegroundColor Red
    Write-Host "  Installing IIS..." -ForegroundColor Yellow

    # Install IIS features
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools -All -NoRestart

    Write-Host "  IIS installed. Please restart and run this script again." -ForegroundColor Yellow
    exit 0
}

# Check iisnode
$iisnodeModule = Get-WebGlobalModule -Name "iisnode" -ErrorAction SilentlyContinue
if ($iisnodeModule) {
    Write-Host "  iisnode: Installed" -ForegroundColor Green
} else {
    Write-Host "  iisnode: NOT INSTALLED" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please install iisnode manually:" -ForegroundColor Yellow
    Write-Host "  1. Download from: https://github.com/Azure/iisnode/releases" -ForegroundColor White
    Write-Host "  2. Install: iisnode-full-v0.2.21-x64.msi" -ForegroundColor White
    Write-Host "  3. Run 'iisreset' after installation" -ForegroundColor White
    Write-Host "  4. Run this script again" -ForegroundColor White
    exit 1
}

# Check URL Rewrite module
$urlRewrite = Get-WebGlobalModule -Name "RewriteModule" -ErrorAction SilentlyContinue
if ($urlRewrite) {
    Write-Host "  URL Rewrite: Installed" -ForegroundColor Green
} else {
    Write-Host "  URL Rewrite: NOT INSTALLED" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please install URL Rewrite module:" -ForegroundColor Yellow
    Write-Host "  Download from: https://www.iis.net/downloads/microsoft/url-rewrite" -ForegroundColor White
    exit 1
}

# Step 2: Install npm dependencies
Write-Host ""
Write-Host "[Step 2] Installing npm dependencies..." -ForegroundColor Yellow
Push-Location $SitePath
try {
    npm install --production 2>&1 | Out-Host
    Write-Host "  Dependencies installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "  Error installing dependencies: $_" -ForegroundColor Red
}
Pop-Location

# Step 3: Set folder permissions
Write-Host ""
Write-Host "[Step 3] Setting folder permissions..." -ForegroundColor Yellow

# Grant IIS_IUSRS full control
$acl = Get-Acl $SitePath
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($rule)
Set-Acl $SitePath $acl

# Grant IUSR read access
$rule2 = New-Object System.Security.AccessControl.FileSystemAccessRule("IUSR", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($rule2)
Set-Acl $SitePath $acl

Write-Host "  Permissions set for IIS_IUSRS and IUSR" -ForegroundColor Green

# Step 4: Remove existing site if exists
Write-Host ""
Write-Host "[Step 4] Configuring IIS Site..." -ForegroundColor Yellow

Import-Module WebAdministration

# Check if site exists
$existingSite = Get-WebSite -Name $SiteName -ErrorAction SilentlyContinue
if ($existingSite) {
    Write-Host "  Removing existing site: $SiteName" -ForegroundColor Yellow
    Remove-WebSite -Name $SiteName
}

# Check if app pool exists
$existingPool = Get-WebAppPoolState -Name $SiteName -ErrorAction SilentlyContinue
if ($existingPool) {
    Write-Host "  Removing existing app pool: $SiteName" -ForegroundColor Yellow
    Remove-WebAppPool -Name $SiteName
}

# Step 5: Create Application Pool
Write-Host ""
Write-Host "[Step 5] Creating Application Pool..." -ForegroundColor Yellow

New-WebAppPool -Name $SiteName
Set-ItemProperty -Path "IIS:\AppPools\$SiteName" -Name "managedRuntimeVersion" -Value ""
Set-ItemProperty -Path "IIS:\AppPools\$SiteName" -Name "processModel.identityType" -Value "ApplicationPoolIdentity"

Write-Host "  Application Pool '$SiteName' created" -ForegroundColor Green

# Step 6: Create Website
Write-Host ""
Write-Host "[Step 6] Creating Website..." -ForegroundColor Yellow

New-WebSite -Name $SiteName -Port $Port -PhysicalPath $SitePath -ApplicationPool $SiteName
Write-Host "  Website '$SiteName' created on port $Port" -ForegroundColor Green

# Step 7: Configure Firewall
Write-Host ""
Write-Host "[Step 7] Configuring Firewall..." -ForegroundColor Yellow

$firewallRule = Get-NetFirewallRule -DisplayName "CMO API" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "  Firewall rule already exists" -ForegroundColor Gray
} else {
    New-NetFirewallRule -DisplayName "CMO API" -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow | Out-Null
    Write-Host "  Firewall rule created for port $Port" -ForegroundColor Green
}

# Step 8: Start Website
Write-Host ""
Write-Host "[Step 8] Starting Website..." -ForegroundColor Yellow

Start-WebSite -Name $SiteName
Start-WebAppPool -Name $SiteName

Write-Host "  Website started successfully!" -ForegroundColor Green

# Step 9: Test the API
Write-Host ""
Write-Host "[Step 9] Testing API..." -ForegroundColor Yellow

Start-Sleep -Seconds 3  # Wait for site to start

try {
    $response = Invoke-WebRequest -Uri "http://localhost:$Port/api/health" -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "  API Health Check: SUCCESS" -ForegroundColor Green
        Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  API Health Check: FAILED" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Check iisnode logs at: $SitePath\iisnode\" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  IIS Configuration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Site Details:" -ForegroundColor Cyan
Write-Host "  Name:         $SiteName" -ForegroundColor White
Write-Host "  Port:         $Port" -ForegroundColor White
Write-Host "  Path:         $SitePath" -ForegroundColor White
Write-Host "  App Pool:     $SiteName" -ForegroundColor White
Write-Host ""
Write-Host "API Endpoints:" -ForegroundColor Cyan
Write-Host "  Local:   http://localhost:$Port/api/health" -ForegroundColor White
Write-Host "  Network: http://192.168.10.100:$Port/api/health" -ForegroundColor White
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  Restart Site:  Restart-WebSite -Name '$SiteName'" -ForegroundColor White
Write-Host "  Stop Site:     Stop-WebSite -Name '$SiteName'" -ForegroundColor White
Write-Host "  View Logs:     Get-Content '$SitePath\iisnode\*.txt' -Tail 50" -ForegroundColor White
Write-Host "  IIS Reset:     iisreset" -ForegroundColor White
Write-Host ""
