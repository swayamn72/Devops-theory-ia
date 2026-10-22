<#
.SYNOPSIS
    Runs Trivy security scans locally (Filesystem, Docker Image, and SBOM generation).
.DESCRIPTION
    Checks for either local 'trivy' CLI or falls back to official 'aquasec/trivy' Docker container.
#>

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DevSecOps Local Security Scan (Trivy)  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if Docker is available
try {
    $dockerCheck = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Docker daemon is not running. Please start Docker Desktop to scan container images."
        $hasDocker = $false
    } else {
        $hasDocker = $true
    }
} catch {
    $hasDocker = $false
}

# Check if Trivy CLI is installed
$hasTrivyCli = $null -ne (Get-Command trivy -ErrorAction SilentlyContinue)

if (-not $hasTrivyCli -and -not $hasDocker) {
    Write-Error "Neither Trivy CLI nor Docker was found running. Please install Trivy (choco install trivy) or start Docker Desktop."
    exit 1
}

# Step 1: Filesystem Scan
Write-Host "`n[1/3] Running Trivy Filesystem Scan (Vulnerabilities, Secrets, Misconfigs)..." -ForegroundColor Yellow
if ($hasTrivyCli) {
    trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL .
} else {
    $currentDir = (Get-Location).Path -replace '\\', '/'
    docker run --rm -v "${currentDir}:/src" -w /src aquasec/trivy:latest fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL .
}

# Step 2: Build Docker Image
if ($hasDocker) {
    Write-Host "`n[2/3] Building local Docker image (demo-app:local)..." -ForegroundColor Yellow
    docker build -t demo-app:local .

    # Step 3: Container Image Scan
    Write-Host "`n[3/3] Running Trivy Container Image Scan (Gate: HIGH/CRITICAL)..." -ForegroundColor Yellow
    if ($hasTrivyCli) {
        trivy image --severity HIGH,CRITICAL --ignore-unfixed demo-app:local
        
        Write-Host "`nGenerating CycloneDX SBOM..." -ForegroundColor Cyan
        trivy image --format cyclonedx --output sbom.cdx.json demo-app:local
    } else {
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "${currentDir}:/src" -w /src aquasec/trivy:latest image --severity HIGH,CRITICAL --ignore-unfixed demo-app:local

        Write-Host "`nGenerating CycloneDX SBOM..." -ForegroundColor Cyan
        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "${currentDir}:/src" -w /src aquasec/trivy:latest image --format cyclonedx --output /src/sbom.cdx.json demo-app:local
    }

    Write-Host "`n[SUCCESS] Local scan completed! SBOM saved to sbom.cdx.json." -ForegroundColor Green
} else {
    Write-Host "`nSkipping Docker Image scan and SBOM generation because Docker daemon is not active." -ForegroundColor Yellow
}
