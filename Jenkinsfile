pipeline {

    agent {
        docker {
            image 'joseperezg/node22-dockercli'
            args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        DOCKERHUB_USER = "joseperezg"
        IMAGE_NAME     = "backend-test"

        // Credenciales
        DOCKERHUB_CRED_ID = "docker-hub-creds"
        GITHUB_CRED_ID    = "github-packages-token"
        KUBECONFIG_ID     = "kubeconfig-file"

        // GHCR
        GITHUB_USER = "joseperezg-duoc"
        GHCR_IMAGE  = "ghcr.io/${GITHUB_USER}/${IMAGE_NAME}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install & Test & Build') {
            steps {
                sh 'npm ci'
                sh 'npm test'
                sh 'npm run build || echo "No hay build"'
            }
        }

        stage('Docker Build') {
            steps {
                sh """
                    docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:latest .
                    docker tag ${DOCKERHUB_USER}/${IMAGE_NAME}:latest ${DOCKERHUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}

                    docker tag ${DOCKERHUB_USER}/${IMAGE_NAME}:latest ${GHCR_IMAGE}:latest
                    docker tag ${DOCKERHUB_USER}/${IMAGE_NAME}:latest ${GHCR_IMAGE}:${BUILD_NUMBER}
                """
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKERHUB_CRED_ID, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh """
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push ${DH_USER}/${IMAGE_NAME}:latest
                        docker push ${DH_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Push to GHCR') {
            steps {
                withCredentials([string(credentialsId: GITHUB_CRED_ID, variable: 'GH_PAT')]) {
                    sh """
                        echo "$GH_PAT" | docker login ghcr.io -u ${GITHUB_USER} --password-stdin

                        docker push ${GHCR_IMAGE}:latest
                        docker push ${GHCR_IMAGE}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: KUBECONFIG_ID, variable: 'KUBECONFIG')]) {
                    sh """
                        export KUBECONFIG=$KUBECONFIG
                        NAMESPACE=JosePerezG-duoc
                        DEPLOYMENT_NAME=backend-test-deployment

                        kubectl -n $NAMESPACE set image deployment/$DEPLOYMENT_NAME backend=${GHCR_IMAGE}:${BUILD_NUMBER} --record
                        kubectl -n $NAMESPACE rollout status deployment/$DEPLOYMENT_NAME --timeout=120s
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✔ Deploy exitoso! Imagen: ${BUILD_NUMBER}"
        }
        failure {
            echo "❌ Pipeline falló. Revisar logs."
        }
    }
}
