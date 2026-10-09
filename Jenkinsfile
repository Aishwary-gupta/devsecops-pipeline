pipeline {
    agent any

    environment {
        APP_NAME           = 'secure-devsecops-service'
        IMAGE_NAME         = "devsecops-org/${APP_NAME}"
        IMAGE_TAG          = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        SONAR_QUBE_SERVER  = 'SonarQube-Server'
        SLACK_CHANNEL      = '#devsecops-alerts'
        SNYK_TOKEN         = credentials('snyk-api-token')
        SLACK_TOKEN        = credentials('slack-webhook-credentials')
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '15'))
        disableConcurrentBuilds()
    }

    stages {
        // =====================================================================
        // STAGE 1: Build & Dependencies
        // =====================================================================
        stage('1. Build & Dependencies') {
            steps {
                echo '=== [STAGE 1] Installing Dependencies and Building Application ==='
                sh '''
                    node -v
                    npm -v
                    npm ci
                '''
            }
        }

        // =====================================================================
        // STAGE 2: Unit Testing & Code Coverage
        // =====================================================================
        stage('2. Unit Tests & Coverage') {
            steps {
                echo '=== [STAGE 2] Running Unit Tests with Coverage Thresholds ==='
                sh '''
                    npm run test:ci
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'coverage/**', allowEmptyArchive: true
                }
            }
        }

        // =====================================================================
        // STAGE 3: SonarQube SAST & Quality Gate
        // =====================================================================
        stage('3. SonarQube SAST Analysis') {
            steps {
                echo '=== [STAGE 3] Running SonarQube Static Analysis ==='
                withSonarQubeEnv("${SONAR_QUBE_SERVER}") {
                    sh '''
                        sonar-scanner \
                            -Dsonar.projectKey=${APP_NAME} \
                            -Dsonar.sources=src \
                            -Dsonar.tests=tests \
                            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                            -Dsonar.qualitygate.wait=true
                    '''
                }
            }
        }

        stage('Quality Gate Enforcement') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to SonarQube Quality Gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }

        // =====================================================================
        // STAGE 4: Docker Multi-Stage Build
        // =====================================================================
        stage('4. Docker Build') {
            steps {
                echo "=== [STAGE 4] Building Hardened Docker Image: ${IMAGE_NAME}:${IMAGE_TAG} ==="
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} \
                                 -t ${IMAGE_NAME}:latest .
                """
            }
        }

        // =====================================================================
        // STAGE 5: Trivy Container Image & Secrets Scan
        // =====================================================================
        stage('5. Trivy Security Scan') {
            steps {
                echo '=== [STAGE 5] Trivy Vulnerability & Secret Scanning ==='
                sh '''
                    # 5a. Secret scanning across workspace
                    trivy fs --security-checks secret --severity CRITICAL,HIGH --exit-code 1 .

                    # 5b. Container image vulnerability scanning (blocking gate)
                    trivy image --severity CRITICAL,HIGH --ignore-unfixed --exit-code 1 ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        // =====================================================================
        // STAGE 6: Software Bill of Materials (SBOM) Generation
        // =====================================================================
        stage('6. SBOM Generation') {
            steps {
                echo '=== [STAGE 6] Generating CycloneDX SBOM Artifact ==='
                sh """
                    mkdir -p reports
                    trivy image --format cyclonedx --output reports/sbom.cdx.json ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/sbom.cdx.json', allowEmptyArchive: false
                }
            }
        }

        // =====================================================================
        // STAGE 7: Snyk SCA Dependency Security Scan
        // =====================================================================
        stage('7. Snyk SCA Scan') {
            steps {
                echo '=== [STAGE 7] Snyk Software Composition Analysis (SCA) ==='
                sh '''
                    snyk auth ${SNYK_TOKEN}
                    snyk test --severity-threshold=high --json-file-output=reports/snyk-report.json
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/snyk-report.json', allowEmptyArchive: true
                }
            }
        }

        // =====================================================================
        // STAGE 8: Infrastructure as Code (Checkov) & OPA Policies
        // =====================================================================
        stage('8. Checkov IaC & OPA Governance') {
            steps {
                echo '=== [STAGE 8] Checkov IaC Analysis & OPA Rego Validation ==='
                sh '''
                    # Checkov IaC scan on manifests and Dockerfile
                    checkov -d . --framework kubernetes,dockerfile --soft-fail false

                    # OPA Conftest Policy evaluation
                    conftest test -p policy/k8s_security.rego k8s/
                    conftest test -p policy/dockerfile_security.rego Dockerfile
                '''
            }
        }

        // =====================================================================
        // STAGE 9: Deployment Gate
        // =====================================================================
        stage('9. Secure Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo "=== [STAGE 9] Rolling out version ${IMAGE_TAG} to Staging ==="
                sh """
                    echo "Updating deployment manifest with new secure image digest..."
                    sed -i "s|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml
                    # kubectl apply -f k8s/ --dry-run=client
                    echo "Deployment successfully staged."
                """
            }
        }
    }

    // =========================================================================
    // POST ACTIONS: Slack Notifications
    // =========================================================================
    post {
        success {
            echo 'Pipeline completed successfully!'
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'good',
                message: "🛡️ DevSecOps Pipeline SUCCESS!\nJob: ${env.JOB_NAME} [Build #${env.BUILD_NUMBER}]\nImage: ${IMAGE_NAME}:${IMAGE_TAG}\nAll security gates (SonarQube, Trivy, Snyk, Checkov, OPA) PASSED."
            )
        }
        failure {
            echo 'Pipeline failed a security gate!'
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'danger',
                message: "⚠️ DevSecOps Pipeline FAILED!\nJob: ${env.JOB_NAME} [Build #${env.BUILD_NUMBER}]\nSecurity Gate violation detected. Check console logs for details."
            )
        }
    }
}
