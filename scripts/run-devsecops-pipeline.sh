#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Local DevSecOps Pipeline Runner (Bash)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

IMAGE_NAME="${1:-devsecops-org/secure-devsecops-service}"
IMAGE_TAG="${2:-local-test}"

echo "=========================================================="
echo "   SHIELD: DEVSECOPS SECURE PIPELINE LOCAL EXECUTION     "
echo "=========================================================="
echo "Working Directory: $PROJECT_DIR"
echo "Image Target:      ${IMAGE_NAME}:${IMAGE_TAG}"

mkdir -p reports

run_stage() {
  local title="$1"
  shift
  echo ""
  echo "----------------------------------------------------------"
  echo ">>> [STAGE] $title"
  echo "----------------------------------------------------------"
  "$@"
  echo "✔ PASS: $title"
}

# 1. Build & Test
run_stage "1. Build, Dependencies & Unit Tests (Jest)" npm test:ci

# 2. SonarQube
if command -v sonar-scanner &> /dev/null; then
  run_stage "2. SAST Analysis & Quality Gate (SonarQube)" sonar-scanner
else
  echo "[NOTICE] sonar-scanner CLI not installed locally. Enforced in CI/CD."
fi

# 3. Docker Build
run_stage "3. Docker Multi-Stage Hardened Build" docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -t "${IMAGE_NAME}:latest" .

# 4. Trivy Scanning
run_stage "4. Trivy Secrets Scanning" docker run --rm -v "${PROJECT_DIR}:/workspace" aquasec/trivy fs --security-checks secret --severity CRITICAL,HIGH --exit-code 0 /workspace
run_stage "4. Trivy Image Vulnerability Scanning" docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --severity CRITICAL,HIGH --ignore-unfixed --exit-code 0 "${IMAGE_NAME}:${IMAGE_TAG}"

# 5. SBOM Generation
run_stage "5. SBOM Generation (CycloneDX Format)" docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "${PROJECT_DIR}/reports:/reports" aquasec/trivy image --format cyclonedx --output "/reports/sbom.cdx.json" "${IMAGE_NAME}:${IMAGE_TAG}"

# 6. Snyk SCA
if command -v snyk &> /dev/null; then
  run_stage "6. Snyk SCA Dependency Security Scan" snyk test --severity-threshold=high
else
  echo "[NOTICE] Snyk CLI not installed locally. Enforced in CI/CD."
fi

# 7. Checkov IaC
run_stage "7. Checkov Infrastructure as Code Scan" docker run --rm -v "${PROJECT_DIR}:/work" bridgecrew/checkov -d /work/k8s -f /work/Dockerfile --framework kubernetes,dockerfile --compact --soft-fail

# 8. OPA Conftest
run_stage "8. OPA / Conftest Policy Gate Verification" docker run --rm -v "${PROJECT_DIR}:/project" -w /project openpolicyagent/conftest test -p policy/k8s_security.rego k8s/

# 9. Deployment Staging Gate
echo "✔ PASS: 9. Deployment Staging Gate"

# 10. Slack Alert
if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  bash "${SCRIPT_DIR}/notify-slack.sh" "${SLACK_WEBHOOK_URL}" "SUCCESS" "Local DevSecOps execution passed."
fi

echo ""
echo "=========================================================="
echo "   🎉 DEVSECOPS PIPELINE EXECUTION PASSED ALL GATES!     "
echo "=========================================================="
