# Test login with real AdminSecurity user
$baseUrl = "http://localhost:8080/api"

Write-Host "Testing CMO API Login with AdminSecurity Table" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Test login endpoint with real user
Write-Host "1. Testing Login with user '100018'..." -ForegroundColor Yellow
$loginBody = @{
    username = "100018"
    password = "Irfan@123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10

    # Store token for next requests
    $token = $response.data.accessToken
    Write-Host ""
    Write-Host "Access Token (first 50 chars): $($token.Substring(0, [Math]::Min(50, $token.Length)))..." -ForegroundColor Cyan

    Write-Host ""
    Write-Host "2. Testing Profile Endpoint..." -ForegroundColor Yellow
    $headers = @{
        "Authorization" = "Bearer $token"
    }

    $profileResponse = Invoke-RestMethod -Uri "$baseUrl/auth/profile" -Method Get -Headers $headers
    Write-Host "✅ Profile retrieved successfully!" -ForegroundColor Green
    Write-Host "Profile Data:" -ForegroundColor Green
    $profileResponse | ConvertTo-Json -Depth 10

} catch {
    Write-Host "❌ Request failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Test completed!" -ForegroundColor Cyan
