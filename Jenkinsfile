pipeline {
    agent any

    environment {
        IMAGE_NAME = "backend-test"
        DOCKERHUB_USER = "joseperezg"
        GHCR_USER = "joseperezg-duoc"
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
                    def shortCommit = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
                    env.IMAGE_TAG = shortCommit

                    sh """
                        docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} .
                        docker tag ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKERHUB_USER}/${IMAGE_NAME}:latest

                        docker tag ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ghcr.io/${GHCR_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker tag ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ghcr.io/${GHCR_USER}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh """
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:latest
                        docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Push to GHCR') {
            steps {
                withCredentials([string(credentialsId: 'github-packages-token', variable: 'GH_PAT')]) {
                    sh """
                        echo "$GH_PAT" | docker login ghcr.io -u ${GHCR_USER} --password-stdin
                        docker push ghcr.io/${GHCR_USER}/${IMAGE_NAME}:latest
                        docker push ghcr.io/${GHCR_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker logout ghcr.io
                    """
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        echo "Usando kubeconfig: $KUBECONFIG_FILE"
                        
                        docker run --rm --network host \
                            -v $KUBECONFIG_FILE:/kubeconfig:ro \
                            -e KUBECONFIG=/kubeconfig \
                            bitnami/kubectl:latest set image deployment/${IMAGE_NAME} ${IMAGE_NAME}=ghcr.io/${GHCR_USER}/${IMAGE_NAME}:${IMAGE_TAG} --namespace=default

                        docker run --rm --network host \
                            -v $KUBECONFIG_FILE:/kubeconfig:ro \
                            -e KUBECONFIG=/kubeconfig \
                            bitnami/kubectl:latest rollout status deployment/${IMAGE_NAME} --namespace=default
                    """
                }
            }
        }
    }
}
