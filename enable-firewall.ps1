# Run this script as Administrator to allow port 8080 through Windows Firewall

Write-Host "Creating firewall rule for CMO API..." -ForegroundColor Yellow

try {
    New-NetFirewallRule -DisplayName "CMO API" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
    Write-Host "✅ Firewall rule created successfully!" -ForegroundColor Green
    Write-Host "Port 8080 is now open for incoming connections" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create firewall rule" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Open Windows Firewall manually and add port 8080" -ForegroundColor Yellow
}

pause
