# 🛡️ DevSecOps Pipeline: End-to-End Secure CI/CD System

[![CI/CD Status](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions%20%7C%20Jenkins-blue)](https://github.com)
[![Docker](https://img.shields.io/badge/Docker-Multi--Stage-blue?logo=docker)](https://www.docker.com/)
[![SonarQube](https://img.shields.io/badge/SAST-SonarQube-4B9CD3?logo=sonarqube)](https://www.sonarqube.org/)
[![Trivy](https://img.shields.io/badge/Vulnerability-Trivy-007ACC?logo=aquasecurity)](https://aquasecurity.github.io/trivy/)
[![SBOM](https://img.shields.io/badge/SBOM-CycloneDX-green)](https://cyclonedx.org/)
[![Snyk](https://img.shields.io/badge/SCA-Snyk-4C5A67?logo=snyk)](https://snyk.io/)
[![Checkov](https://img.shields.io/badge/IaC-Checkov-2C3E50)](https://www.checkov.io/)
[![OPA](https://img.shields.io/badge/Policy-OPA%2FConftest-gray?logo=openpolicyagent)](https://www.openpolicyagent.org/)
[![Slack](https://img.shields.io/badge/Alerts-Slack-4A154B?logo=slack)](https://slack.com/)

---

## 1. Project Architecture

This repository delivers a **production-grade DevSecOps pipeline** that implements "Shift-Left Security" across every phase of the CI/CD lifecycle.

```
Git Push / Pull Request
         │
         ▼
┌─────────────────────────────────┐
│ 1. Build & Unit Test (Jest)     │  ---> Coverage Threshold ≥ 80%
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 2. SonarQube SAST & Quality Gate│  ---> Blocker Bugs: 0, Security Rating: A
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 3. Docker Multi-Stage Build     │  ---> Non-root user, Minimal Alpine base
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 4. Trivy Secrets & CVE Scan     │  ---> Fail on CRITICAL/HIGH vulnerabilities
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 5. SBOM Generation              │  ---> CycloneDX JSON (Supply chain audit)
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 6. Snyk SCA Dependency Audit    │  ---> Zero high-severity open source CVEs
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 7. Checkov IaC Security Scan    │  ---> Hard-fail on HIGH/CRITICAL in K8s/Docker
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 8. OPA / Conftest Policy Check  │  ---> Rego Policy-as-Code Enforcement
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 9. Staging Deployment Gate      │  ---> Automated / Approval-gated rollout
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 10. Slack Real-Time Alerts      │  ---> Success / Failure webhook broadcast
└─────────────────────────────────┘
```

---

## 2. Directory Structure

```
devsecops-pipeline/
├── .github/workflows/
│   └── devsecops-pipeline.yml   # GitHub Actions End-to-End Workflow
├── Jenkinsfile                  # Jenkins Declarative Pipeline
├── Dockerfile                   # Hardened Multi-Stage Containerfile
├── .dockerignore                # Image footprint & leak prevention
├── docker-compose.yml           # Local microservice & SonarQube stack
├── package.json                 # Node.js app dependencies & Jest coverage
├── sonar-project.properties     # SonarQube SAST & Quality Gate settings
├── .trivyignore                 # Trivy vulnerability exception tracking
├── trivy-secret.yaml            # Trivy custom secret detection rules
├── .checkov.yaml                # Checkov IaC scanner policies
├── .snyk                        # Snyk SCA configuration
├── src/
│   ├── app.js                   # Secure Express API (Helmet, Rate/Size limits)
│   └── server.js                # Graceful shutdown & lifecycle handlers
├── tests/
│   └── app.test.js              # Unit & security integration test suite
├── k8s/                         # Hardened Kubernetes Manifests
│   ├── deployment.yaml          # Non-root, read-only root, limits, drops ALL
│   ├── service.yaml             # ClusterIP service
│   └── configmap.yaml           # Configuration map
├── policy/                      # OPA Rego Policy-as-Code Definitions
│   ├── k8s_security.rego        # K8s enforcement: registry, limits, non-root
│   └── dockerfile_security.rego # Dockerfile rules: no root user, no latest
├── scripts/
│   ├── run-devsecops-pipeline.ps1 # Local PowerShell pipeline runner
│   ├── run-devsecops-pipeline.sh  # Local Bash pipeline runner
│   ├── notify-slack.ps1         # PowerShell Slack alert dispatcher
│   └── notify-slack.sh          # Bash Slack alert dispatcher
└── README.md                    # Project documentation & configuration guide
```

---

## 3. Security Gates & Enforcement Matrix

| Gate | Tool | Target | Passing Threshold | Blocking Condition |
| :--- | :--- | :--- | :--- | :--- |
| **Code Quality & SAST** | SonarQube | Source code (`src/`) | Quality Gate = `OK` | Security Rating < A, Coverage < 80%, Blocker Bugs > 0 |
| **Secrets Scanning** | Trivy | Repository & Image layers | 0 detected credentials | Any API key, token, or private key detected |
| **Image Vulnerabilities** | Trivy | Container image | 0 CRITICAL CVEs (unfixed) | Any exploitable CRITICAL or HIGH CVE with patch |
| **Supply Chain (SBOM)** | Trivy / Syft | Software bill of materials | Valid CycloneDX JSON | Failed generation or unsigned digest |
| **Dependency Security (SCA)** | Snyk | `package.json` dependencies | High severity = 0 | Unpatched vulnerable transitive/direct dependencies |
| **IaC Misconfigurations** | Checkov | `k8s/*.yaml`, `Dockerfile` | 0 HIGH / CRITICAL violations | Root execution, missing limits, privileged flags |
| **Governance & Policy** | OPA / Conftest | K8s manifests, Dockerfile | 0 `deny` violations | Unapproved registry, missing replica count, capability leak |
| **Incident Response** | Slack | Entire pipeline | Real-time card broadcast | Triggered immediately on build or gate failure |

---

## 4. Local Execution & Testing

You can run the entire DevSecOps pipeline right on your local machine using the provided runner scripts.

### Prerequisites
* [Node.js](https://nodejs.org/) (v18+)
* [Docker Desktop](https://www.docker.com/)

### Running on Windows (PowerShell)
```powershell
cd "C:\Users\AISHWARY GUPTA\Documents\devsecops-pipeline"
.\scripts\run-devsecops-pipeline.ps1
```

### Running on Linux / macOS / WSL (Bash)
```bash
chmod +x scripts/run-devsecops-pipeline.sh
./scripts/run-devsecops-pipeline.sh
```

### Running the Microservice Locally
```bash
# Install dependencies
npm install

# Run unit tests with code coverage enforcement
npm test

# Start the application
npm start
```

### Running SonarQube Locally via Docker Compose
```bash
docker compose up -d sonarqube
```
Access SonarQube at: `http://localhost:9000` (Default credentials: `admin` / `admin`).

---

## 5. CI/CD Orchestration Setup

### Option A: GitHub Actions Setup
1. Push this repository to your GitHub account:
   ```bash
   git init
   git add .
   git commit -m "feat: complete DevSecOps pipeline implementation"
   git remote add origin https://github.com/<your-username>/<repo-name>.git
   git push -u origin main
   ```
2. Navigate to **Settings** > **Secrets and variables** > **Actions** in your GitHub repository.
3. Configure the following secrets:
   * `SONAR_TOKEN`: Your SonarQube / SonarCloud authentication token.
   * `SONAR_HOST_URL`: The URL of your SonarQube instance (e.g. `https://sonarcloud.io` or `https://sonar.yourdomain.com`).
   * `SNYK_TOKEN`: Your Snyk API token from [snyk.io](https://snyk.io).
   * `SLACK_WEBHOOK_URL`: Your Slack Incoming Webhook URL.

### Option B: Jenkins Setup
1. Create a **Pipeline** job in Jenkins pointing to the `Jenkinsfile`.
2. Configure credentials in **Manage Jenkins** > **Credentials**:
   * `snyk-api-token`: Secret text with Snyk API Key.
   * `slack-webhook-credentials`: Secret text or Slack plugin integration.
3. Configure SonarQube server under **Manage Jenkins** > **Configure System** > **SonarQube servers** named `SonarQube-Server`.
4. Install recommended Jenkins plugins:
   * *SonarQube Scanner*
   * *Slack Notification*
   * *Docker Pipeline*
   * *Pipeline: Stage View*

---

## 6. Policy-as-Code (OPA Rego) Rules

The custom policies located in `policy/k8s_security.rego` strictly enforce:
* **OPA-001**: Containers and Pods must run as non-root (`runAsNonRoot: true`).
* **OPA-002 / OPA-003**: Containers must define both CPU and Memory limits to safeguard cluster resources.
* **OPA-004**: Reject mutable `:latest` image tags in production deployments.
* **OPA-005**: Containers must drop `ALL` Linux capabilities (`drop: ["ALL"]`).
* **OPA-006**: Root filesystem must be read-only (`readOnlyRootFilesystem: true`).
* **OPA-007**: Images must only originate from approved registries (`ghcr.io/devsecops-org/`, `123456789012.dkr.ecr.us-east-1.amazonaws.com/`).
* **OPA-008**: High Availability: Production deployments must have at least 2 replicas.

---

## 7. Slack Alerts Integration

When a build runs, rich interactive Block Kit notifications are broadcast to your designated channel.

To generate a Slack Incoming Webhook:
1. Go to [api.slack.com/apps](https://api.slack.com/apps) and create a new App.
2. Enable **Incoming Webhooks** and click **Add New Webhook to Workspace**.
3. Select your notification channel (e.g., `#devsecops-alerts`).
4. Set the resulting Webhook URL in your environment:
   ```powershell
   $env:SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00/B00/XXXX"
   ```
