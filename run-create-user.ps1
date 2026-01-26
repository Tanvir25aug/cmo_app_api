# Run SQL script to create test user

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Creating Test User in Database" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$server = "192.168.10.104"
$database = "MeterOCRDESCO"
$username = "rdpdc"
$password = "Oculin@123"
$scriptFile = "D:\OTBL Project\cmo-api\database\QUICK_CREATE_USER.sql"

Write-Host "Server:   $server" -ForegroundColor Gray
Write-Host "Database: $database" -ForegroundColor Gray
Write-Host "Script:   $scriptFile`n" -ForegroundColor Gray

try {
    sqlcmd -S $server -d $database -U $username -P $password -i $scriptFile

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "User Created Successfully! ✅" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "Login Credentials:" -ForegroundColor Yellow
    Write-Host "  Email:    testuser@otbl.com" -ForegroundColor White
    Write-Host "  Password: Abid@123`n" -ForegroundColor White

} catch {
    Write-Host "`n❌ Error running script" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Gray
}
