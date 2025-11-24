pipeline {
    agent any

    environment {
        DH_USER = credentials('dockerhub-username')
        DH_PASS = credentials('dockerhub-password')
        GH_TOKEN = credentials('github-token')
        KUBECONFIG_FILE = credentials('kubeconfig-file') // archivo kubeconfig subido a Jenkins Credentials
        NAMESPACE = 'JosePerezG-duoc'
        DEPLOYMENT_NAME = 'backend-test-deployment'
        IMAGE_NAME = 'ghcr.io/joseperezg-duoc/backend-test'
        IMAGE_TAG = '28'
    }

    stages {
        stage('Checkout') {
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
                    docker build -t joseperezg/backend-test:latest -t joseperezg/backend-test:${IMAGE_TAG} .
                    docker tag joseperezg/backend-test:latest ${IMAGE_NAME}:latest
                    docker tag joseperezg/backend-test:latest ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', passwordVariable: 'DH_PASS', usernameVariable: 'DH_USER')]) {
                    sh """
                        echo $DH_PASS | docker login -u $DH_USER --password-stdin
                        docker push joseperezg/backend-test:latest
                        docker push joseperezg/backend-test:${IMAGE_TAG}
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
                        docker push ${IMAGE_NAME}:latest
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker logout ghcr.io
                    """
                }
            }
        }

        stage('Update Kubernetes Deployment') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-file', variable: 'KUBECONFIG')]) {
                    sh """
                        export KUBECONFIG=$KUBECONFIG
                        kubectl -n $NAMESPACE set image deployment/$DEPLOYMENT_NAME backend=${IMAGE_NAME}:${IMAGE_TAG}
                        kubectl -n $NAMESPACE rollout status deployment/$DEPLOYMENT_NAME --timeout=120s
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

