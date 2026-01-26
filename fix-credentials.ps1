# Fix GitHub Credentials - Remove old cached credentials
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Fixing GitHub Credentials" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Searching for cached GitHub credentials..." -ForegroundColor Yellow
Write-Host ""

# List all credentials
$credentials = cmdkey /list | Select-String "github"

if ($credentials) {
    Write-Host "Found GitHub credentials:" -ForegroundColor Green
    Write-Host $credentials
    Write-Host ""

    # Remove GitHub credentials
    Write-Host "Removing cached credentials..." -ForegroundColor Yellow

    # Try different GitHub credential targets
    $targets = @(
        "git:https://github.com",
        "github.com",
        "https://github.com"
    )

    foreach ($target in $targets) {
        $result = cmdkey /delete:$target 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Removed: $target" -ForegroundColor Green
        }
    }
} else {
    Write-Host "No GitHub credentials found in Windows Credential Manager." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Credentials cleared!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Now run the push-to-github.ps1 script to upload your code." -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
