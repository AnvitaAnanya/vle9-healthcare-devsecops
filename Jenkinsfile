
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        IMAGE_NAME = 'vle9-healthcare:v1'
        ZAP_REPORT = 'zap-report.html'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'VLE-9 source code checked out.'
            }
        }

        stage('SonarQube SAST') {
            steps {
                withCredentials([
                    string(credentialsId: 'Anvita', variable: 'SONAR_TOKEN')
                ]) {
                    sh '''
                        sonar-scanner \
                          -Dsonar.host.url=https://sonarcloud.io \
                          -Dsonar.token="$SONAR_TOKEN"
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t "$IMAGE_NAME" .'
            }
        }

        stage('Container Vulnerability Scan') {
            steps {
                sh '''
                    trivy image \
                      --scanners vuln \
                      --severity HIGH,CRITICAL \
                      --exit-code 1 \
                      "$IMAGE_NAME"
                '''
            }
        }

        stage('Validate Kubernetes Manifests') {
            steps {
                sh '''
                    kubectl apply --dry-run=client -f deployment.yaml
                    kubectl apply --dry-run=client -f service.yaml
                '''
            }
        }

        stage('OWASP ZAP DAST') {
            steps {
                sh '''
                    set -eu

                    mkdir -p zap-reports
                    chmod 777 zap-reports

                    docker rm -f vle9-zap-target >/dev/null 2>&1 || true

                    cleanup() {
                        docker rm -f vle9-zap-target >/dev/null 2>&1 || true
                    }
                    trap cleanup EXIT

                    docker run -d \
                      --name vle9-zap-target \
                      -p 127.0.0.1:18081:8080 \
                      "$IMAGE_NAME"

                    ready=0
                    for attempt in $(seq 1 30); do
                        if curl -fsS http://127.0.0.1:18081/ >/dev/null; then
                            ready=1
                            break
                        fi
                        sleep 2
                    done

                    if [ "$ready" -ne 1 ]; then
                        echo 'Healthcare test container did not become ready.'
                        docker logs vle9-zap-target || true
                        exit 1
                    fi

                    docker run --rm \
                      --network host \
                      -v "$WORKSPACE/zap-reports:/zap/wrk:rw" \
                      ghcr.io/zaproxy/zaproxy:stable \
                      zap-baseline.py \
                      -t http://127.0.0.1:18081 \
                      -r "$ZAP_REPORT"
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'zap-reports/zap-report.html',
                             allowEmptyArchive: true
            sh 'docker rm -f vle9-zap-target >/dev/null 2>&1 || true'
        }
        success {
            echo 'VLE-9 security pipeline completed successfully.'
        }
        failure {
            echo 'VLE-9 pipeline failed. Check the stage logs and archived reports.'
        }
    }
}

