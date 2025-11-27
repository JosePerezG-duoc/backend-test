pipeline {

    agent {
        docker {
            image 'joseperezg/node22-dockercli'
            args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {

        DOCKERHUB_REPO = "joseperezg/backend-test"
        GHCR_REPO      = "ghcr.io/joseperezg-duoc/backend-test"

        DOCKERHUB_CRED = "docker-hub-creds"
        GHCR_CRED      = "github-packages-token"
        KUBECONFIG_ID  = "kubeconfig"

        NAMESPACE      = "joseperezg-duoc"
        DEPLOYMENT     = "backend-test-deployment"

        BUILD_TAG      = "${env.BUILD_NUMBER}"
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
                sh 'npm run build || echo "no build command"'
            }
        }

        stage('Docker Build') {
            steps {
                sh """
                    docker build -t ${DOCKERHUB_REPO}:latest -t ${DOCKERHUB_REPO}:${BUILD_TAG} .
                    docker tag ${DOCKERHUB_REPO}:latest ${GHCR_REPO}:latest
                    docker tag ${DOCKERHUB_REPO}:latest ${GHCR_REPO}:${BUILD_TAG}
                """
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKERHUB_CRED, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh """
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push ${DOCKERHUB_REPO}:latest
                        docker push ${DOCKERHUB_REPO}:${BUILD_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Push to GHCR') {
            steps {
                withCredentials([string(credentialsId: GHCR_CRED, variable: 'GH_PAT')]) {
                    sh """
                        echo "$GH_PAT" | docker login ghcr.io -u joseperezg-duoc --password-stdin
                        docker push ${GHCR_REPO}:latest
                        docker push ${GHCR_REPO}:${BUILD_TAG}
                        docker logout ghcr.io
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: KUBECONFIG_ID, variable: 'KUBECONFIG_FILE')]) {

                    sh """
                        export KUBECONFIG=\$KUBECONFIG_FILE

                        echo "Actualizando deployment en namespace: ${NAMESPACE}"

                        kubectl -n ${NAMESPACE} set image deployment/${DEPLOYMENT} backend=${GHCR_REPO}:${BUILD_TAG} --record
                        kubectl -n ${NAMESPACE} rollout status deployment/${DEPLOYMENT} --timeout=120s
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✔ Pipeline finalizado correctamente. Imagen: ${BUILD_TAG}"
        }
        failure {
            echo "❌ Pipeline falló. Revisar logs."
        }
    }
}

