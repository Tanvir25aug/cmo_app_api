# =============================================
# Execute CMO Table Creation Script
# =============================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Creating CMO Requests Table" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$server = "192.168.10.104"
$database = "MeterOCRDESCO"
$scriptFile = "D:\OTBL Project\cmo-api\database\create_cmo_table_only.sql"

Write-Host "Server:   $server" -ForegroundColor Gray
Write-Host "Database: $database" -ForegroundColor Gray
Write-Host "Script:   $scriptFile`n" -ForegroundColor Gray

try {
    # Read SQL script
    $sqlScript = Get-Content -Path $scriptFile -Raw

    # Execute using sqlcmd
    Write-Host "Executing SQL script..." -ForegroundColor Yellow

    $output = sqlcmd -S $server -d $database -U rdpdc -P "Oculin@123" -i $scriptFile

    Write-Host "`n$output" -ForegroundColor Green

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Table created successfully! ✅" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan

} catch {
    Write-Host "`n❌ Error creating table" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Gray

    Write-Host "`nAlternative: Run the SQL script manually in SQL Server Management Studio" -ForegroundColor Yellow
    Write-Host "Script location: $scriptFile" -ForegroundColor Gray
}
