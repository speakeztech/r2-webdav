# list-users.ps1 - List all configured users
# Requires PowerShell 7+

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "WebDAV Users" -ForegroundColor Green
Write-Host "============"
Write-Host ""

try {
    # List all secrets to find users
    Write-Host "Checking configured users..." -ForegroundColor Yellow
    
    $SecretsList = & npx wrangler secret list 2>$null | Out-String
    
    # Parse user secrets (pattern: USER_*_PASSWORD)
    $UserSecrets = $SecretsList -split "`n" | Where-Object { $_ -match 'USER_(.+)_PASSWORD' } | ForEach-Object {
        if ($_ -match 'USER_(.+)_PASSWORD') {
            $Matches[1].ToLower()
        }
    }
    
    if ($UserSecrets.Count -eq 0) {
        Write-Host "No users configured" -ForegroundColor Gray
        exit 0
    }
    
    Write-Host "Found $($UserSecrets.Count) user(s):" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($User in $UserSecrets) {
        $BucketName = "$($User.ToLower())-webdav-sync"
        Write-Host "  • $User" -ForegroundColor White
        Write-Host "    Bucket: $BucketName" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "To add a user:    .\add-user.ps1 <username> <password>" -ForegroundColor Cyan
    Write-Host "To remove a user: .\remove-user.ps1 <username>" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to list users: $_"
    exit 1
}