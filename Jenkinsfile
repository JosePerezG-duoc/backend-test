pipeline {
    agent any

    environment {
        // Variables globales si necesitas
        IMAGE_NAME = "joseperezg-duoc/backend-test"
        IMAGE_TAG = "latest"
    }

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            agent {
                docker {
                    image 'joseperezg/jenkins-node-docker-kubectl:latest'
                    args '-u 0:0 -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG .'
            }
        }

        stage('Push Docker Image') {
            agent any
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-user', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    sh """
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push $IMAGE_NAME:$IMAGE_TAG
                        docker logout
                    """
                }
            }
        }

        stage('Other steps if needed') {
            steps {
                echo "Aquí puedes agregar otros pasos como tests o despliegue"
            }
        }

        stage('Cleanup Docker') {
            agent any
            steps {
                echo "Cleaning up Docker system..."
                sh 'docker system prune -af || true'
            }
        }

    }

    post {
        success {
            echo "Pipeline finalizó correctamente"
        }
        failure {
            echo "Pipeline FALLÓ. Revisar logs"
        }
    }
}

