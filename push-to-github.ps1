# GitHub Push Helper Script
# This script will help you push your code to GitHub

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CMO API - GitHub Push Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Repository details
$repoUrl = "https://github.com/Tanvir25aug/comAppApiNode.git"
$username = "Tanvir25aug"

Write-Host "Repository: $repoUrl" -ForegroundColor Yellow
Write-Host ""

# Check if remote exists
$remoteExists = git remote get-url origin 2>$null
if (-not $remoteExists) {
    Write-Host "Adding GitHub remote..." -ForegroundColor Green
    git remote add origin $repoUrl
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AUTHENTICATION REQUIRED" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You need a GitHub Personal Access Token to push." -ForegroundColor Yellow
Write-Host ""
Write-Host "If you DON'T have a token yet:" -ForegroundColor White
Write-Host "1. Visit: https://github.com/settings/tokens" -ForegroundColor White
Write-Host "2. Click 'Generate new token (classic)'" -ForegroundColor White
Write-Host "3. Give it a name: 'CMO API Upload'" -ForegroundColor White
Write-Host "4. Select scope: 'repo' (check the box)" -ForegroundColor White
Write-Host "5. Click 'Generate token'" -ForegroundColor White
Write-Host "6. COPY the token immediately!" -ForegroundColor White
Write-Host ""

# Prompt for token
Write-Host "========================================" -ForegroundColor Cyan
$token = Read-Host "Enter your Personal Access Token (or press Ctrl+C to cancel)"

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host ""
    Write-Host "No token provided. Exiting..." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Pushing to GitHub..." -ForegroundColor Green
Write-Host ""

# Create URL with token
$authUrl = "https://${username}:${token}@github.com/Tanvir25aug/comAppApiNode.git"

# Update remote with authenticated URL
git remote set-url origin $authUrl

# Push to GitHub
git push -u origin main

# Check if push was successful
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  SUCCESS! Code uploaded to GitHub" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "View your repository at:" -ForegroundColor Yellow
    Write-Host "$repoUrl" -ForegroundColor Cyan
    Write-Host ""

    # Remove token from URL for security
    git remote set-url origin $repoUrl
    Write-Host "Credentials removed from git config for security." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  PUSH FAILED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "1. Your token is valid" -ForegroundColor White
    Write-Host "2. Your token has 'repo' permissions" -ForegroundColor White
    Write-Host "3. You have access to the repository" -ForegroundColor White
    Write-Host ""

    # Remove token from URL for security
    git remote set-url origin $repoUrl
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
