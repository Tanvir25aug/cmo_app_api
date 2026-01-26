# =============================================
# Register Test User via API
# =============================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Register Test User" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080/api"

# Test user data
$registerBody = @{
    username = "testuser"
    email = "test@example.com"
    password = "password123"
    fullName = "Test User"
    phone = "01712345678"
} | ConvertTo-Json

Write-Host "Registering user:" -ForegroundColor Yellow
Write-Host "  Username: testuser" -ForegroundColor Gray
Write-Host "  Email: test@example.com" -ForegroundColor Gray
Write-Host "  Password: password123" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/register" `
        -Method Post `
        -ContentType "application/json" `
        -Body $registerBody

    Write-Host "✅ User registered successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "User Details:" -ForegroundColor Cyan
    Write-Host "  ID: $($response.data.user.id)" -ForegroundColor Gray
    Write-Host "  Username: $($response.data.user.username)" -ForegroundColor Gray
    Write-Host "  Email: $($response.data.user.email)" -ForegroundColor Gray
    Write-Host "  Full Name: $($response.data.user.fullName)" -ForegroundColor Gray
    Write-Host "  Role: $($response.data.user.role)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Access Token (first 50 chars):" -ForegroundColor Cyan
    $token = $response.data.accessToken
    Write-Host "  $($token.Substring(0, [Math]::Min(50, $token.Length)))..." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "You can now login with:" -ForegroundColor Green
    Write-Host "  Email: test@example.com" -ForegroundColor Yellow
    Write-Host "  Password: password123" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Cyan

} catch {
    Write-Host "❌ Registration failed" -ForegroundColor Red

    if ($_.ErrorDetails.Message) {
        try {
            $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Host "Error: $($errorJson.message)" -ForegroundColor Gray

            if ($errorJson.errors) {
                Write-Host "`nValidation errors:" -ForegroundColor Yellow
                foreach ($error in $errorJson.errors) {
                    Write-Host "  - $($error.path): $($error.msg)" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
        }
    } else {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray
    }

    Write-Host "`nMake sure:" -ForegroundColor Yellow
    Write-Host "  1. API is running (npm start)" -ForegroundColor Gray
    Write-Host "  2. Database tables are created" -ForegroundColor Gray
    Write-Host "  3. User doesn't already exist" -ForegroundColor Gray
}
