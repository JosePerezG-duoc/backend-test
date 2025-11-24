pipeline {
    agent any

    environment {
        NODE_VERSION = '22'
        DOCKER_IMAGE = "joseperezg/backend-test"
        GHCR_IMAGE = "ghcr.io/joseperezg-duoc/backend-test"
        VERSION_TAG = "28"
        NAMESPACE = "JosePerezG-duoc"
        DEPLOYMENT_NAME = "backend-test-deployment"
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

        stage('Testing') {
            steps {
                sh 'npm test'
            }
        }

        stage('Build app') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Build Docker image') {
            steps {
                sh """
                    docker build -t ${DOCKER_IMAGE}:latest -t ${DOCKER_IMAGE}:${VERSION_TAG} .
                    docker tag ${DOCKER_IMAGE}:latest ${GHCR_IMAGE}:latest
                    docker tag ${DOCKER_IMAGE}:latest ${GHCR_IMAGE}:${VERSION_TAG}
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-username', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh """
                        echo $DH_PASS | docker login -u $DH_USER --password-stdin
                        docker push ${DOCKER_IMAGE}:latest
                        docker push ${DOCKER_IMAGE}:${VERSION_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Push to GitHub Container Registry') {
            steps {
                withCredentials([string(credentialsId: 'github-token', variable: 'GH_TOKEN')]) {
                    sh """
                        echo $GH_TOKEN | docker login ghcr.io -u joseperezg-duoc --password-stdin
                        docker push ${GHCR_IMAGE}:latest
                        docker push ${GHCR_IMAGE}:${VERSION_TAG}
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
                        docker run --rm -v $KUBECONFIG:/root/.kube/config bitnami/kubectl:latest \
                            -n ${NAMESPACE} set image deployment/${DEPLOYMENT_NAME} backend=${GHCR_IMAGE}:${VERSION_TAG}
                    """
                }
            }
        }
    }

    post {
        always {
            node {
                echo 'Pipeline finalizado. Limpiando Docker...'
                sh 'docker system prune -af'
            }
        }

        failure {
            node {
                echo 'Pipeline FALLÓ. Revisar logs.'
            }
        }
    }
}
