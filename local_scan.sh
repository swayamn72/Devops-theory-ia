#!/usr/bin/env bash
# DevSecOps local security scan (needs Docker or local Trivy)
set -e

echo "========================================"
echo "  DevSecOps Local Security Scan (Trivy)  "
echo "========================================"

# Check if trivy command exists locally
if command -v trivy >/dev/null 2>&1; then
  TRIVY_CMD="trivy"
elif command -v docker >/dev/null 2>&1; then
  echo "Trivy CLI not found locally; using official aquasec/trivy Docker container..."
  TRIVY_CMD="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/src -w /src aquasec/trivy:latest"
else
  echo "Error: Neither 'trivy' CLI nor 'docker' is installed."
  exit 1
fi

echo -e "\n[1/3] Filesystem Scan (vuln, secret, misconfig)..."
$TRIVY_CMD fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL .

echo -e "\n[2/3] Building local Docker image..."
docker build -t demo-app:local .

echo -e "\n[3/3] Image Scan (Gate: HIGH/CRITICAL)..."
$TRIVY_CMD image --severity HIGH,CRITICAL --ignore-unfixed demo-app:local

echo -e "\nGenerating CycloneDX SBOM..."
$TRIVY_CMD image --format cyclonedx --output sbom.cdx.json demo-app:local

echo -e "\n[SUCCESS] Local scan completed! SBOM saved to sbom.cdx.json."
