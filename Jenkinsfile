pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = 'dockerhub-creds'
        GHCR_CREDENTIALS       = 'ghcr-token'
        KUBECONFIG_FILE        = 'kubeconfig-file'
        NAMESPACE              = 'JosePerezG-duoc'
        DEPLOYMENT_NAME        = 'backend-test-deployment'
        IMAGE_NAME             = 'backend-test'
        IMAGE_TAG              = '18'
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
                script {
                    sh """
                        docker build -t joseperezg/${IMAGE_NAME}:latest -t joseperezg/${IMAGE_NAME}:${IMAGE_TAG} .
                        docker tag joseperezg/${IMAGE_NAME}:latest ghcr.io/joseperezg-duoc/${IMAGE_NAME}:latest
                        docker tag joseperezg/${IMAGE_NAME}:latest ghcr.io/joseperezg-duoc/${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push joseperezg/${IMAGE_NAME}:latest
                        docker push joseperezg/${IMAGE_NAME}:${IMAGE_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Push to GitHub Container Registry') {
            steps {
                withCredentials([string(credentialsId: GHCR_CREDENTIALS, variable: 'GH_TOKEN')]) {
                    sh """
                        echo $GH_TOKEN | docker login ghcr.io -u joseperezg-duoc --password-stdin
                        docker push ghcr.io/joseperezg-duoc/${IMAGE_NAME}:latest
                        docker push ghcr.io/joseperezg-duoc/${IMAGE_NAME}:${IMAGE_TAG}
                        docker logout ghcr.io
                    """
                }
            }
        }

        stage('Update Kubernetes Deployment') {
            steps {
                withCredentials([file(credentialsId: KUBECONFIG_FILE, variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        docker run --rm \\
                            -v ${KUBECONFIG_FILE}:/root/.kube/config \\
                            lachlanevenson/k8s-kubectl:latest \\
                            set image deployment/${DEPLOYMENT_NAME} backend=ghcr.io/joseperezg-duoc/${IMAGE_NAME}:${IMAGE_TAG} \\
                            --namespace=${NAMESPACE} --record
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -af'
        }
        failure {
            echo 'Pipeline FALLÓ. Revisar logs.'
        }
    }
}
