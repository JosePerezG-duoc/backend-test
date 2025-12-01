pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-creds')
        GHCR_TOKEN = credentials('github-packages-token')
        IMAGE_NAME = "backend-test"
        GHCR_NAMESPACE = "joseperezg-duoc"   // <--- CORREGIDO: todo minúscula
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker image') {
            steps {
                script {
                    COMMIT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

                    sh """
                    docker build -t ${DOCKERHUB_CREDENTIALS_USR}/${IMAGE_NAME}:${COMMIT} .
                    docker tag ${DOCKERHUB_CREDENTIALS_USR}/${IMAGE_NAME}:${COMMIT} ${DOCKERHUB_CREDENTIALS_USR}/${IMAGE_NAME}:latest
                    docker tag ${DOCKERHUB_CREDENTIALS_USR}/${IMAGE_NAME}:${COMMIT} ghcr.io/${GHCR_NAMESPACE}/${IMAGE_NAME}:${COMMIT}
                    docker tag ${DOCKERHUB_CREDENTIALS_USR}/${IMAGE_NAME}:${COMMIT} ghcr.io/${GHCR_NAMESPACE}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                script {
                    sh """
                    echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
                    docker push ${DOCKERHUB_CREDENTIALS_USR}/${IMAGE_NAME}:${COMMIT}
                    docker push ${DOCKERHUB_CREDENTIALS_USR}/${IMAGE_NAME}:latest
                    docker logout
                    """
                }
            }
        }

        stage('Push to GHCR') {
            steps {
                script {
                    sh """
                    echo ${GHCR_TOKEN} | docker login ghcr.io -u ${GHCR_NAMESPACE} --password-stdin
                    docker push ghcr.io/${GHCR_NAMESPACE}/${IMAGE_NAME}:${COMMIT}
                    docker push ghcr.io/${GHCR_NAMESPACE}/${IMAGE_NAME}:latest
                    docker logout ghcr.io
                    """
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                script {
                    sh """
                    kubectl set image deployment/backend-test backend-test=ghcr.io/${GHCR_NAMESPACE}/${IMAGE_NAME}:${COMMIT} --record
                    kubectl rollout status deployment/backend-test
                    """
                }
            }
        }

    }
}
