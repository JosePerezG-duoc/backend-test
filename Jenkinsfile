pipeline {
    agent any

    environment {
        DOCKER_HUB_USER = 'joseperezg'
        GHCR_USER       = 'joseperezg-duoc'
        IMAGE_NAME      = 'backend-test'
        TAG             = '18'
        NAMESPACE       = 'JosePerezG-duoc'
        DEPLOYMENT_NAME = 'backend-test-deployment'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Install dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test'
            }
        }

        stage('Build App') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Build Docker image') {
            steps {
                sh """
                    docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${TAG} .
                    docker tag ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest ghcr.io/${GHCR_USER}/${IMAGE_NAME}:latest
                    docker tag ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest ghcr.io/${GHCR_USER}/${IMAGE_NAME}:${TAG}
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([string(credentialsId: 'docker-hub-password', variable: 'DH_PASS')]) {
                    sh """
                        echo $DH_PASS | docker login -u ${DOCKER_HUB_USER} --password-stdin
                        docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                        docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Push to GitHub Container Registry') {
            steps {
                withCredentials([string(credentialsId: 'ghcr-token', variable: 'GH_TOKEN')]) {
                    sh """
                        echo $GH_TOKEN | docker login ghcr.io -u ${GHCR_USER} --password-stdin
                        docker push ghcr.io/${GHCR_USER}/${IMAGE_NAME}:latest
                        docker push ghcr.io/${GHCR_USER}/${IMAGE_NAME}:${TAG}
                        docker logout ghcr.io
                    """
                }
            }
        }

        stage('Update Kubernetes Deployment') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-file', variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=$KUBECONFIG_FILE
                        kubectl -n ${NAMESPACE} set image deployment/${DEPLOYMENT_NAME} backend=ghcr.io/${GHCR_USER}/${IMAGE_NAME}:${TAG} --record
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up Docker system...'
            sh 'docker system prune -af'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline FALLÓ. Revisar logs.'
        }
    }
}
