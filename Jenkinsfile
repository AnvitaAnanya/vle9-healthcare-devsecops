pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        IMAGE_NAME = 'vle9-healthcare:v1'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'VLE-9 source code checked out from GitHub'
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
    }

    post {
        success {
            echo 'VLE-9 security pipeline completed successfully.'
        }
        failure {
            echo 'VLE-9 pipeline failed. Check the stage logs for details.'
        }
    }
}
