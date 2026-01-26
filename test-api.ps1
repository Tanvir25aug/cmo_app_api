# =============================================
# CMO API - Quick Test Script
# =============================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing CMO API" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080/api"

# Test 1: Health Check
Write-Host "1. Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "   ✅ API is running!" -ForegroundColor Green
    Write-Host "   Environment: $($health.environment)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ API is not responding" -ForegroundColor Red
    Write-Host "   Make sure the API is started with: npm start" -ForegroundColor Gray
    exit
}

Write-Host ""

# Test 2: Login (update with your actual credentials)
Write-Host "2. Testing Login..." -ForegroundColor Yellow
Write-Host "   Enter your email: " -ForegroundColor Gray -NoNewline
$email = Read-Host
Write-Host "   Enter your password: " -ForegroundColor Gray -NoNewline
$password = Read-Host -AsSecureString
$passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
)

$loginBody = @{
    email = $email
    password = $passwordPlain
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody

    Write-Host "   ✅ Login successful!" -ForegroundColor Green
    Write-Host "   User: $($loginResponse.data.user.username)" -ForegroundColor Gray
    Write-Host "   Role: $($loginResponse.data.user.role)" -ForegroundColor Gray

    $token = $loginResponse.data.accessToken
    Write-Host "`n   Access Token (first 50 chars):" -ForegroundColor Gray
    Write-Host "   $($token.Substring(0, [Math]::Min(50, $token.Length)))..." -ForegroundColor DarkGray

    # Test 3: Get Profile
    Write-Host "`n3. Testing Profile Endpoint..." -ForegroundColor Yellow
    $headers = @{
        Authorization = "Bearer $token"
    }

    $profile = Invoke-RestMethod -Uri "$baseUrl/auth/profile" `
        -Method Get `
        -Headers $headers

    Write-Host "   ✅ Profile retrieved!" -ForegroundColor Green
    Write-Host "   Full Name: $($profile.data.fullName)" -ForegroundColor Gray
    Write-Host "   Email: $($profile.data.email)" -ForegroundColor Gray

    # Test 4: Get CMOs
    Write-Host "`n4. Testing CMO List Endpoint..." -ForegroundColor Yellow
    $cmos = Invoke-RestMethod -Uri "$baseUrl/cmo" `
        -Method Get `
        -Headers $headers

    Write-Host "   ✅ CMO list retrieved!" -ForegroundColor Green
    Write-Host "   Total CMOs: $($cmos.pagination.total)" -ForegroundColor Gray

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "All tests passed! ✅" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan

} catch {
    Write-Host "   ❌ Login failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray

    if ($_.ErrorDetails.Message) {
        $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "   Details: $($errorJson.message)" -ForegroundColor Gray
    }
}
