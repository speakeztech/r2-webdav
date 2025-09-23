# add-user.ps1 - Add a new user to the R2-WebDAV system
# Usage: .\scripts\add-user.ps1 -Username <username> -Password <password>

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$Password,

    [Parameter(Mandatory=$false)]
    [switch]$SkipDeploy
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Validate username (alphanumeric and underscore only)
if ($Username -notmatch '^[a-zA-Z0-9_]+$') {
    Write-Error "Error: Username must be alphanumeric (underscores allowed)"
    exit 1
}

# Convert username to lowercase for consistency
$Username = $Username.ToLower()

# Deterministic naming convention
$BucketName = "$Username-webdav-bucket"
$BucketBinding = "${Username}_webdav_sync"
$PasswordSecret = "USER_$($Username.ToUpper())_PASSWORD"

Write-Host ""
Write-Host "R2-WebDAV User Setup" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host "Username: $Username" -ForegroundColor White
Write-Host "Bucket: $BucketName" -ForegroundColor White
Write-Host ""

try {
    # Step 1: Check if bucket already exists
    Write-Host "[1/4] Checking for existing R2 bucket..." -ForegroundColor Yellow
    $existingBuckets = & npx wrangler r2 bucket list 2>&1
    if ($existingBuckets -match $BucketName) {
        Write-Host "  ⚠ Bucket $BucketName already exists, skipping creation" -ForegroundColor DarkYellow
    } else {
        Write-Host "[2/4] Creating R2 bucket: $BucketName" -ForegroundColor Yellow
        & npx wrangler r2 bucket create $BucketName
        if ($LASTEXITCODE -ne 0) { throw "Failed to create R2 bucket" }
        Write-Host "  ✓ Bucket created successfully" -ForegroundColor Green
    }

    # Step 2: Store password as secret
    Write-Host "[3/4] Storing password as secret: $PasswordSecret" -ForegroundColor Yellow
    $Password | & npx wrangler secret put $PasswordSecret --name r2-webdav 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Secret may already exist or there was an issue. Continuing..."
    } else {
        Write-Host "  ✓ Password stored securely" -ForegroundColor Green
    }

    # Step 3: Check if binding already exists in wrangler.toml
    Write-Host "[4/4] Updating wrangler.toml configuration..." -ForegroundColor Yellow
    $wranglerPath = Join-Path (Split-Path $PSScriptRoot -Parent) "wrangler.toml"
    $wranglerContent = Get-Content -Path $wranglerPath -Raw
    if ($wranglerContent -match "binding\s*=\s*`"$BucketBinding`"") {
        Write-Host "  ⚠ Binding already exists in wrangler.toml, skipping" -ForegroundColor DarkYellow
    } else {
        # Add bucket binding to wrangler.toml
        $TomlContent = @"

[[r2_buckets]]
binding = "$BucketBinding"
bucket_name = "$BucketName"
"@
        Add-Content -Path $wranglerPath -Value $TomlContent
        Write-Host "  ✓ Configuration updated" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Green
    Write-Host " ✅ User setup complete!" -ForegroundColor Green
    Write-Host "════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    if (-not $SkipDeploy) {
        Write-Host "Deploying worker..." -ForegroundColor Yellow
        & npx wrangler deploy
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Worker deployed successfully" -ForegroundColor Green
        } else {
            Write-Warning "Deployment failed. Run 'npx wrangler deploy' manually"
        }
    } else {
        Write-Host "Deploy the worker to activate changes:" -ForegroundColor Cyan
        Write-Host "  npx wrangler deploy" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "Connection Details:" -ForegroundColor Cyan
    Write-Host "  URL:      https://r2-webdav.engineering-0c5.workers.dev/webdav" -ForegroundColor White
    Write-Host "  Username: $Username" -ForegroundColor White
    Write-Host "  Password: [as provided]" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Error "Failed to set up user: $_"
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Make sure you're logged in: npx wrangler login" -ForegroundColor Gray
    Write-Host "  2. Check your account has R2 access" -ForegroundColor Gray
    Write-Host "  3. Verify the bucket name is unique" -ForegroundColor Gray
    exit 1
}