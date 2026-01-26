# =============================================
# Test Login with Existing ASP.NET User
# =============================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CMO API - Login Test" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080/api"

# Test 1: Health Check
Write-Host "1. Testing API Health..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "   ✅ API is running!" -ForegroundColor Green
    Write-Host "   Environment: $($health.environment)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ API is not responding" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    Write-Host "`n   Make sure the API is started with: npm start" -ForegroundColor Yellow
    exit
}

Write-Host ""

# Test 2: Login
Write-Host "2. Testing Login with Existing User..." -ForegroundColor Yellow
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

Write-Host "`n   Attempting login..." -ForegroundColor Gray

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody

    Write-Host "`n   ✅ Login successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   User Details:" -ForegroundColor Cyan
    Write-Host "   ─────────────────────────────────" -ForegroundColor Gray
    Write-Host "   ID:        $($loginResponse.data.user.id)" -ForegroundColor White
    Write-Host "   Username:  $($loginResponse.data.user.username)" -ForegroundColor White
    Write-Host "   Email:     $($loginResponse.data.user.email)" -ForegroundColor White
    Write-Host "   Full Name: $($loginResponse.data.user.fullName)" -ForegroundColor White
    Write-Host "   Phone:     $($loginResponse.data.user.phone)" -ForegroundColor White
    Write-Host "   Role ID:   $($loginResponse.data.user.roleId)" -ForegroundColor White
    Write-Host "   Active:    $($loginResponse.data.user.isActive)" -ForegroundColor White

    $token = $loginResponse.data.accessToken
    Write-Host "`n   Access Token (first 60 chars):" -ForegroundColor Cyan
    Write-Host "   $($token.Substring(0, [Math]::Min(60, $token.Length)))..." -ForegroundColor DarkGray

    # Save token to file for future tests
    $token | Out-File -FilePath "token.txt" -NoNewline
    Write-Host "`n   Token saved to: token.txt" -ForegroundColor Gray

    # Test 3: Get Profile
    Write-Host "`n3. Testing Profile Endpoint..." -ForegroundColor Yellow
    $headers = @{
        Authorization = "Bearer $token"
    }

    try {
        $profile = Invoke-RestMethod -Uri "$baseUrl/auth/profile" `
            -Method Get `
            -Headers $headers

        Write-Host "   ✅ Profile retrieved successfully!" -ForegroundColor Green
        Write-Host "   User: $($profile.data.fullName)" -ForegroundColor Gray

        # Test 4: Get CMOs
        Write-Host "`n4. Testing CMO List Endpoint..." -ForegroundColor Yellow
        $cmos = Invoke-RestMethod -Uri "$baseUrl/cmo" `
            -Method Get `
            -Headers $headers

        Write-Host "   ✅ CMO list retrieved!" -ForegroundColor Green
        Write-Host "   Total CMOs: $($cmos.pagination.total)" -ForegroundColor Gray

        if ($cmos.pagination.total -gt 0) {
            Write-Host "`n   Recent CMOs:" -ForegroundColor Cyan
            foreach ($cmo in $cmos.data | Select-Object -First 3) {
                Write-Host "   - $($cmo.customerName) ($($cmo.status))" -ForegroundColor White
            }
        }

        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "All tests passed! ✅" -ForegroundColor Green
        Write-Host "========================================`n" -ForegroundColor Cyan

    } catch {
        Write-Host "   ⚠️  Profile/CMO test failed" -ForegroundColor Yellow
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    }

} catch {
    Write-Host "`n   ❌ Login failed" -ForegroundColor Red

    if ($_.ErrorDetails.Message) {
        try {
            $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "   Error: $($errorJson.message)" -ForegroundColor Gray

            if ($errorJson.errors) {
                Write-Host "`n   Validation errors:" -ForegroundColor Yellow
                foreach ($error in $errorJson.errors) {
                    Write-Host "   - $($error.path): $($error.msg)" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host "   Error: $($_.ErrorDetails.Message)" -ForegroundColor Gray
        }
    } else {
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
    }

    Write-Host "`n   Possible issues:" -ForegroundColor Yellow
    Write-Host "   1. Incorrect email or password" -ForegroundColor Gray
    Write-Host "   2. User account not activated" -ForegroundColor Gray
    Write-Host "   3. Password hash format mismatch" -ForegroundColor Gray
    Write-Host "`n   Check API logs for more details: pm2 logs cmo-api" -ForegroundColor Gray
}
