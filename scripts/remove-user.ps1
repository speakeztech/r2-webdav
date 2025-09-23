# remove-user.ps1 - Remove a user from the WebDAV system
# Requires PowerShell 7+

param(
    [Parameter(Mandatory=$true)]
    [string]$Username
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Deterministic naming
$BucketName = "$($Username.ToLower())-webdav-sync"
$PasswordSecret = "USER_$($Username.ToUpper())_PASSWORD"

Write-Host "Removing user: $Username" -ForegroundColor Yellow
Write-Host "================================"
Write-Host ""
Write-Host "⚠️  WARNING: This will delete all user data!" -ForegroundColor Red

$Confirmation = Read-Host "Type 'DELETE' to confirm"
if ($Confirmation -ne 'DELETE') {
    Write-Host "Aborted" -ForegroundColor Yellow
    exit 0
}

try {
    # Step 1: Delete R2 bucket
    Write-Host "1. Deleting R2 bucket: $BucketName" -ForegroundColor Yellow
    & npx wrangler r2 bucket delete $BucketName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  (bucket may not exist)" -ForegroundColor Gray
    }

    # Step 2: Delete password secret
    Write-Host "2. Deleting password secret: $PasswordSecret" -ForegroundColor Yellow
    & npx wrangler secret delete $PasswordSecret 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  (secret may not exist)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "✅ User removed" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: Remove the bucket binding from wrangler.toml and redeploy" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to remove user: $_"
    exit 1
}