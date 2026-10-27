# 📚 Complete DevSecOps Learning Guide & Tech Stack Reference

This guide provides a structured breakdown of every technology, security scanner, and concept used in this project. It is designed to take you from beginner to confident practitioner in modern DevSecOps.

---

## Quick Reference Index

1. [Core Concept: What is DevSecOps & Shift-Left?](#1-core-concept-what-is-devsecops--shift-left)
2. [Docker & Container Hardening](#2-docker--container-hardening)
3. [CI/CD Orchestration (GitHub Actions & Jenkins)](#3-cicd-orchestration-github-actions--jenkins)
4. [SAST & Code Quality (SonarQube)](#4-sast--code-quality-sonarqube)
5. [Container & Secret Scanning (Trivy)](#5-container--secret-scanning-trivy)
6. [Software Supply Chain & SBOM (CycloneDX)](#6-software-supply-chain--sbom-cyclonedx)
7. [Software Composition Analysis (Snyk)](#7-software-composition-analysis-snyk)
8. [Infrastructure as Code Security (Checkov)](#8-infrastructure-as-code-security-checkov)
9. [Policy-as-Code (OPA & Conftest)](#9-policy-as-code-opa--conftest)
10. [Alerting & Incident Response (Slack Webhooks)](#10-alerting--incident-response-slack-webhooks)
11. [Recommended 4-Week Learning Roadmap](#11-recommended-4-week-learning-roadmap)

---

## 1. Core Concept: What is DevSecOps & Shift-Left?

### Why it exists
Historically, security testing was performed at the very end of the delivery cycle (right before production release) by a separate security team. If a critical flaw was found, deployments were delayed for weeks, or worse, vulnerabilities made it to production.

**DevSecOps** integrates security practices into every phase of the CI/CD pipeline ("Shift-Left"). Security checks run automatically on every `git push` or `pull request`.

### Key Terms to Learn
* **Shift-Left**: Moving security audits earlier in the development process when bugs are cheap and easy to fix.
* **Security Gate**: An automated rule that fails the pipeline (blocks deployment) if a vulnerability threshold is exceeded.
* **CVE (Common Vulnerabilities and Exposures)**: The standardized public catalog of known cyber security vulnerabilities.
* **CVSS (Common Vulnerability Scoring System)**: Score from 0.0 to 10.0 indicating vulnerability severity (Low, Medium, High, Critical).

---

## 2. Docker & Container Hardening

### What it does in this project
Packages the application into an isolated, lightweight container image that runs reliably across any environment.

### What you need to learn
1. **Multi-Stage Builds**: Using separate `builder` and `runner` stages to keep compilers and build dependencies out of the final production image.
2. **Non-Root Execution**: Why running as `root` in a container is dangerous and how `USER appuser:appgroup` prevents container breakout exploits.
3. **Minimal Base Images**: Difference between Debian/Ubuntu base images vs `alpine` or `distroless` (Alpine has fewer packages, drastically reducing the CVE attack surface).
4. **Container Healthchecks**: Defining `HEALTHCHECK` instructions so container runtimes (Kubernetes/Docker) know if an app is truly healthy.

### Where it is used in the repository
* [Dockerfile](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/Dockerfile)
* [.dockerignore](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/.dockerignore)
* [docker-compose.yml](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/docker-compose.yml)

### Recommended References & Documentation
* [Docker Official Documentation: Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
* [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
* [CIS Docker Benchmark Guidelines](https://www.cisecurity.org/benchmark/docker)

---

## 3. CI/CD Orchestration (GitHub Actions & Jenkins)

### What it does in this project
The CI/CD orchestrator is the engine that detects git commits, runs test suites, triggers security scanners sequentially, enforces security gates, and initiates deployment.

### A. GitHub Actions
* **What to learn**:
  * YAML workflow syntax (`on: [push, pull_request]`).
  * Jobs vs Steps (`needs:` dependency chain for parallel/serial execution).
  * Secrets management (`${{ secrets.SONAR_TOKEN }}`).
  * Pre-built community Actions (`actions/checkout@v4`, `aquasecurity/trivy-action`).
  * Artifact archiving (`actions/upload-artifact@v4`).
* **Where it is used**:
  * [.github/workflows/devsecops-pipeline.yml](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/.github/workflows/devsecops-pipeline.yml)
* **Official Reference**: [GitHub Actions Official Documentation](https://docs.github.com/en/actions)

### B. Jenkins
* **What to learn**:
  * Declarative Pipeline syntax (`pipeline { agent any ... }`).
  * Stage blocks and shell execution (`sh '''...'''`).
  * Quality Gate waiting (`waitForQualityGate()`).
  * Credential binding (`credentials('snyk-api-token')`).
  * Post-build actions (`post { success {} failure {} }`).
* **Where it is used**:
  * [Jenkinsfile](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/Jenkinsfile)
* **Official Reference**: [Jenkins Declarative Pipeline Syntax Guide](https://www.jenkins.io/doc/book/pipeline/syntax/)

---

## 4. SAST & Code Quality (SonarQube)

### What it does in this project
**SAST (Static Application Security Testing)**: Analyzes source code without executing it. It detects security flaws (SQL injection, XSS, insecure cookies), bug patterns, code smells, and ensures automated test coverage is sufficient.

### What you need to learn
1. **Quality Gates**: Organizational criteria that must pass (e.g. 0 Blocker/Critical bugs, test coverage ≥ 80%).
2. **LCOV / Coverage Reports**: How unit test frameworks (like Jest) output coverage data (`coverage/lcov.info`) that SonarQube ingests.
3. **sonar-scanner CLI**: Parameters like `sonar.projectKey`, `sonar.sources`, and `sonar.qualitygate.wait=true`.

### Where it is used in the repository
* [sonar-project.properties](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/sonar-project.properties)
* Configured in Stage 2 of both GitHub Actions and Jenkinsfile.

### Recommended References & Documentation
* [SonarQube Official Documentation](https://docs.sonarsource.com/sonarqube/latest/)
* [Understanding SonarQube Quality Gates](https://docs.sonarsource.com/sonarqube/latest/instance-administration/quality-gates/)
* [OWASP SAST Overview](https://owasp.org/www-community/Source_Code_Analysis_Tools)

---

## 5. Container & Secret Scanning (Trivy)

### What it does in this project
Trivy is a comprehensive security scanner by Aqua Security. It performs two critical functions:
1. **Container Image Scanning**: Detects known CVEs inside OS libraries (like OpenSSL or curl) and application dependencies.
2. **Secrets Scanning**: Scans code and image layers for leaked passwords, AWS keys, Slack tokens, or unencrypted private keys.

### What you need to learn
1. **Exit Code Gates**: Using `--exit-code 1` so any detected critical vulnerability fails the CI build.
2. **Severity Filtering**: Focusing on `--severity CRITICAL,HIGH` and `--ignore-unfixed` (ignoring issues where no vendor patch exists yet).
3. **Secret Detection Rules**: Regex-based detection of API tokens.

### Where it is used in the repository
* [.trivyignore](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/.trivyignore)
* [trivy-secret.yaml](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/trivy-secret.yaml)
* Stage 4 of GitHub Actions and Jenkinsfile.

### Recommended References & Documentation
* [Trivy Documentation by Aqua Security](https://aquasecurity.github.io/trivy/latest/)
* [Trivy Secret Scanning Guide](https://aquasecurity.github.io/trivy/latest/docs/scanner/secret/)

---

## 6. Software Supply Chain & SBOM (CycloneDX)

### What it does in this project
**SBOM (Software Bill of Materials)**: An inventory of every component, library, and transitive dependency inside your software artifact. It ensures software supply chain transparency.

### What you need to learn
1. **Why SBOMs matter**: If a major vulnerability strikes (e.g. Log4j / SolarWinds), security teams search their SBOM catalog to identify which services are affected in seconds.
2. **CycloneDX vs SPDX**: CycloneDX is an OWASP-backed standard designed specifically for application security and supply chain analysis.
3. **Format**: CycloneDX output in JSON format (`sbom.cdx.json`).

### Where it is used in the repository
* Stage 5 of GitHub Actions and Jenkinsfile: `trivy image --format cyclonedx --output reports/sbom.cdx.json`.

### Recommended References & Documentation
* [OWASP CycloneDX Specification](https://cyclonedx.org/)
* [CISA Guide to Software Bill of Materials (SBOM)](https://www.cisa.gov/sbom)

---

## 7. Software Composition Analysis (Snyk)

### What it does in this project
**SCA (Software Composition Analysis)**: While SAST looks at the code *you wrote*, SCA inspects the *third-party libraries you imported* (e.g. `express`, `lodash`, `axios` in `package.json`).

### What you need to learn
1. **Transitive Dependencies**: Vulnerabilities introduced not by your code, but by dependencies of your dependencies.
2. **License Compliance**: Ensuring third-party libraries don't use licenses (like GPL) that might conflict with proprietary commercial software.
3. **Snyk CLI Commands**: `snyk test`, `snyk monitor`, and `.snyk` policy rules.

### Where it is used in the repository
* [.snyk](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/.snyk)
* Stage 6 of GitHub Actions and Jenkinsfile.

### Recommended References & Documentation
* [Snyk Official Documentation](https://docs.snyk.io/)
* [OWASP Top 10 - A06: Vulnerable and Outdated Components](https://owasp.org/Top10/A06_2021-Vulnerable_and_Outdated_Components/)

---

## 8. Infrastructure as Code Security (Checkov)

### What it does in this project
**IaC Security**: Static analysis scanner created by Bridgecrew/Palo Alto Networks. It scans Kubernetes YAML files, Terraform, Helm charts, and Dockerfiles to prevent infrastructure misconfigurations before they reach cloud clusters.

### What you need to learn
1. **Kubernetes Security Contexts**:
   * `runAsNonRoot: true` (disallow root containers).
   * `readOnlyRootFilesystem: true` (prevent malware from writing malicious executables to disk).
   * `capabilities: drop: ["ALL"]` (drop dangerous Linux kernel capabilities).
   * `allowPrivilegeEscalation: false` (prevent setuid escalation).
2. **Resource Requests & Limits**: Defining CPU/memory caps to prevent Denial of Service (DoS) and noisy-neighbor starvation.
3. **Hard-fail vs Soft-fail**: Passing `--soft-fail false` to block CI pipelines when high/critical misconfigurations exist.

### Where it is used in the repository
* [.checkov.yaml](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/.checkov.yaml)
* [k8s/deployment.yaml](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/k8s/deployment.yaml)
* Stage 7 of GitHub Actions and Jenkinsfile.

### Recommended References & Documentation
* [Checkov Official Documentation](https://www.checkov.io/)
* [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

---

## 9. Policy-as-Code (OPA & Conftest)

### What it does in this project
**OPA (Open Policy Agent)** is an open-source, general-purpose policy engine. **Conftest** is a testing utility built on OPA that lets you write assertions against structured configuration files (Kubernetes YAML, Terraform, Dockerfile) using the **Rego** language.

### What you need to learn
1. **The Rego Language**:
   * How `deny[msg] { ... }` blocks work.
   * Testing attributes (e.g. `input.kind == "Deployment"`).
   * Iterating over lists using the `[_]` wildcard.
2. **Policy Enforcement vs Scanner Rules**:
   * Scanners like Checkov check general best practices.
   * OPA enforces **your organization's specific business & regulatory rules** (e.g. "Only pull images from `ghcr.io/devsecops-org/`", "Production must have at least 2 replicas").

### Where it is used in the repository
* [policy/k8s_security.rego](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/policy/k8s_security.rego)
* [policy/dockerfile_security.rego](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/policy/dockerfile_security.rego)
* Stage 8 of GitHub Actions and Jenkinsfile.

### Recommended References & Documentation
* [Open Policy Agent (OPA) Documentation](https://www.openpolicyagent.org/docs/latest/)
* [Conftest Documentation](https://www.conftest.dev/)
* [Rego Interactive Playground](https://play.openpolicyagent.org/)

---

## 10. Alerting & Incident Response (Slack Webhooks)

### What it does in this project
Sends immediate, actionable alert cards to developers and security teams whenever a build succeeds or a security gate fails.

### What you need to learn
1. **Incoming Webhooks**: Generating a webhook URL in Slack API settings.
2. **Block Kit Builder**: JSON layout syntax (`header`, `section`, `fields`, `context`, `actions` button) to build clean message cards.

### Where it is used in the repository
* [scripts/notify-slack.ps1](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/scripts/notify-slack.ps1)
* [scripts/notify-slack.sh](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/scripts/notify-slack.sh)

### Recommended References & Documentation
* [Slack API: Incoming Webhooks Guide](https://api.slack.com/messaging/webhooks)
* [Slack Interactive Block Kit Builder](https://app.slack.com/block-kit-builder)

---

## 11. Recommended 4-Week Learning Roadmap

| Week | Focus Area | Hands-on Exercises in this Project |
| :--- | :--- | :--- |
| **Week 1: Fundamentals** | **Docker & CI/CD Basics** | • Read [Dockerfile](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/Dockerfile). Understand each stage.<br>• Run `npm test` and inspect Jest test coverage.<br>• Study [.github/workflows/devsecops-pipeline.yml](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/.github/workflows/devsecops-pipeline.yml). |
| **Week 2: Code & Dependency Security** | **SonarQube (SAST) & Snyk (SCA)** | • Learn difference between SAST (SonarQube) and SCA (Snyk).<br>• Run SonarQube locally via `docker compose up -d sonarqube`.<br>• Inspect [sonar-project.properties](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/sonar-project.properties) and [.snyk](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/.snyk). |
| **Week 3: Container Security & Supply Chain** | **Trivy & CycloneDX SBOM** | • Run Trivy vulnerability scan against a test image.<br>• Inspect the generated SBOM in `reports/sbom.cdx.json`.<br>• Practice adding a test secret and watching Trivy block it via [trivy-secret.yaml](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/trivy-secret.yaml). |
| **Week 4: Cloud Infrastructure & Policy-as-Code** | **Checkov & OPA / Conftest** | • Study Kubernetes security contexts in [k8s/deployment.yaml](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/k8s/deployment.yaml).<br>• Try modifying [policy/k8s_security.rego](file:///C:/Users/AISHWARY%20GUPTA/Documents/devsecops-pipeline/policy/k8s_security.rego) to add a custom rule.<br>• Run the full pipeline via `.\scripts\run-devsecops-pipeline.ps1`. |
