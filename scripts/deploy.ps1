# deploy.ps1 - Deploy the WebDAV worker
# Requires PowerShell 7+

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "WebDAV Worker Deployment" -ForegroundColor Green
Write-Host "========================"
Write-Host ""

try {
    # Check if wrangler.toml exists
    if (-not (Test-Path "wrangler.toml")) {
        Write-Error "wrangler.toml not found. Are you in the project directory?"
        exit 1
    }

    # Deploy the worker
    Write-Host "Deploying worker to Cloudflare..." -ForegroundColor Yellow
    & npx wrangler deploy
    
    if ($LASTEXITCODE -ne 0) { 
        throw "Deployment failed" 
    }

    Write-Host ""
    Write-Host "✅ Deployment successful!" -ForegroundColor Green
    Write-Host ""
    
    # Get worker URL from wrangler.toml
    $WranglerContent = Get-Content "wrangler.toml"
    $WorkerName = ($WranglerContent | Select-String 'name = "(.+)"').Matches[0].Groups[1].Value
    
    Write-Host "Worker URL: https://$WorkerName.<your-subdomain>.workers.dev/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Users can now connect using their credentials." -ForegroundColor Cyan
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}