pipeline {
    agent {
        docker {
            image 'joseperezg/node22-dockercli:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        DH_USER = credentials('dockerhub-username')     // Credenciales Docker Hub
        DH_PASS = credentials('dockerhub-password')
        GH_USER = credentials('ghcr-username')         // Credenciales GitHub Container Registry
        GH_TOKEN = credentials('ghcr-token')
        KUBECONFIG_FILE = credentials('kubeconfig')    // Kubeconfig para actualizar deployment
        NAMESPACE = 'JosePerezG-duoc'
        DEPLOYMENT_NAME = 'backend-test-deployment'
        IMAGE_NAME = 'backend-test'
        IMAGE_TAG = '18'
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
                    docker build -t ${DH_USER}/${IMAGE_NAME}:latest -t ${DH_USER}/${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${DH_USER}/${IMAGE_NAME}:latest ghcr.io/${GH_USER}/${IMAGE_NAME}:latest
                    docker tag ${DH_USER}/${IMAGE_NAME}:${IMAGE_TAG} ghcr.io/${GH_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                    sh """
                        echo $PASS | docker login -u $USER --password-stdin
                        docker push ${DH_USER}/${IMAGE_NAME}:latest
                        docker push ${DH_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Push to GitHub Container Registry') {
            steps {
                withCredentials([string(credentialsId: 'ghcr-token', variable: 'GH_TOKEN')]) {
                    sh """
                        echo $GH_TOKEN | docker login ghcr.io -u ${GH_USER} --password-stdin
                        docker push ghcr.io/${GH_USER}/${IMAGE_NAME}:latest
                        docker push ghcr.io/${GH_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker logout ghcr.io
                    """
                }
            }
        }

        stage('Update Kubernetes Deployment') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh """
                        docker run --rm -v $KUBECONFIG:/root/.kube/config bitnami/kubectl:latest \
                            kubectl -n ${NAMESPACE} set image deployment/${DEPLOYMENT_NAME} \
                            backend=ghcr.io/${GH_USER}/${IMAGE_NAME}:${IMAGE_TAG} --record
                    """
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning up Docker system..."
            sh 'docker system prune -af'
        }

        success {
            echo 'Pipeline completado correctamente!'
        }

        failure {
            echo 'Pipeline FALLÓ. Revisar logs.'
        }
    }
}
