pipeline {
    agent any

    environment {
        DOCKERHUB_REPO = "joseperezg/backend-test"
        GHCR_REPO = "ghcr.io/joseperezg-duoc/backend-test"
        DEPLOYMENT = "backend-test-deployment"
        NAMESPACE = "jperezg-duoc"
    }

    stages {

        stage('Build Docker image') {
            steps {
                sh """
                    docker build -t ${DOCKERHUB_REPO}:${BUILD_NUMBER} .
                    docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${DOCKERHUB_REPO}:latest
                    docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${GHCR_REPO}:${BUILD_NUMBER}
                    docker tag ${DOCKERHUB_REPO}:${BUILD_NUMBER} ${GHCR_REPO}:latest
                """
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds',
                                usernameVariable: 'DH_USER',
                                passwordVariable: 'DH_PASS')]) {
                    sh """
                        echo $DH_PASS | docker login -u $DH_USER --password-stdin
                        docker push ${DOCKERHUB_REPO}:latest
                        docker push ${DOCKERHUB_REPO}:${BUILD_NUMBER}
                        docker logout
                    """
                }
            }
        }

        stage('Push to GHCR') {
            steps {
                withCredentials([string(credentialsId: 'github-packages-token', variable: 'GH_PAT')]) {
                    sh """
                        echo $GH_PAT | docker login ghcr.io -u joseperezg-duoc --password-stdin
                        docker push ${GHCR_REPO}:latest
                        docker push ${GHCR_REPO}:${BUILD_NUMBER}
                        docker logout ghcr.io
                    """
                }
            }
        }

        stage('Deploy to Minikube') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-jenkins', variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        echo "Usando kubeconfig: $KUBECONFIG_FILE"

                        # Test conexión
                        docker run --rm --network host \
                            -v $KUBECONFIG_FILE:/kubeconfig:ro \
                            -e KUBECONFIG=/kubeconfig \
                            bitnami/kubectl:latest get ns

                        # Actualizar imagen del deployment
                        docker run --rm --network host \
                            -v $KUBECONFIG_FILE:/kubeconfig:ro \
                            -e KUBECONFIG=/kubeconfig \
                            bitnami/kubectl:latest \
                            set image deployment/${DEPLOYMENT} \
                            backend-test=${GHCR_REPO}:${BUILD_NUMBER} \
                            -n ${NAMESPACE}

                        # Esperar rollout
                        docker run --rm --network host \
                            -v $KUBECONFIG_FILE:/kubeconfig:ro \
                            -e KUBECONFIG=/kubeconfig \
                            bitnami/kubectl:latest \
                            rollout status deployment/${DEPLOYMENT} \
                            -n ${NAMESPACE} --timeout=120s
                    """
                }
            }
        }
    }
}
