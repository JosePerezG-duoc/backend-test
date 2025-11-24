pipeline {
    agent {
        docker {
            image 'joseperezg/jenkins-node-docker-kubectl:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        DH_USER = credentials('dockerhub-user')
        DH_PASS = credentials('dockerhub-pass')
        GH_TOKEN = credentials('ghcr-token')
        KUBECONFIG_FILE = credentials('kubeconfig')
        IMAGE_NAME = "backend-test"
        DH_REPO = "joseperezg/${IMAGE_NAME}"
        GHCR_REPO = "ghcr.io/joseperezg-duoc/${IMAGE_NAME}"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${DH_REPO}:latest .
                docker tag ${DH_REPO}:latest ${GHCR_REPO}:latest
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh """
                    echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                    docker push ${DH_REPO}:latest
                    docker logout
                    """
                }
            }
        }

        stage('Push to GitHub Container Registry') {
            steps {
                withCredentials([string(credentialsId: 'ghcr-token', variable: 'GH_TOKEN')]) {
                    sh """
                    echo "$GH_TOKEN" | docker login ghcr.io -u joseperezg-duoc --password-stdin
                    docker push ${GHCR_REPO}:latest
                    docker logout
                    """
                }
            }
        }

        stage('Update Kubernetes Deployment') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    sh """
                    export KUBECONFIG=${KUBECONFIG_FILE}
                    kubectl -n JosePerezG-duoc set image deployment/${IMAGE_NAME}-deployment backend=${GHCR_REPO}:latest --record
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
        failure {
            echo "Pipeline FALLÓ. Revisar logs."
        }
    }
}
