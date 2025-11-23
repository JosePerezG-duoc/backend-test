pipeline {
  agent {
    docker {
      image 'node:22'
      args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
    }
  }

  environment {
    DOCKERHUB_REPO = "joseperezg/backend-test"
    GHCR_REPO = "ghcr.io/JosePerezG-duoc/backend-test"
    BUILD_TAG = "${env.BUILD_NUMBER}"
  }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install dependencies') {
      steps { sh 'npm ci' }
    }

    stage('Testing') {
      steps { sh 'npm test' }
    }

    stage('Build app') {
      steps { sh 'npm run build || echo "no build step"' }
    }

    stage('Build Docker image') {
      steps {
        sh """
          docker build -t ${DOCKERHUB_REPO}:latest -t ${DOCKERHUB_REPO}:${BUILD_TAG} .
          docker tag ${DOCKERHUB_REPO}:latest ${GHCR_REPO}:latest
          docker tag ${DOCKERHUB_REPO}:latest ${GHCR_REPO}:${BUILD_TAG}
        """
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            echo $DH_PASS | docker login -u $DH_USER --password-stdin
            docker push ${DOCKERHUB_REPO}:latest
            docker push ${DOCKERHUB_REPO}:${BUILD_TAG}
            docker logout
          '''
        }
      }
    }

    stage('Push to GitHub Container Registry') {
      steps {
        withCredentials([string(credentialsId: 'github-packages-token', variable: 'GH_TOKEN')]) {
          sh '''
            echo $GH_TOKEN | docker login ghcr.io -u TU_GITHUB_USUARIO --password-stdin
            docker push ${GHCR_REPO}:latest
            docker push ${GHCR_REPO}:${BUILD_TAG}
            docker logout ghcr.io || true
          '''
        }
      }
    }

    stage('Update Kubernetes Deployment') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE
            NAMESPACE=JosePerezG-duoc
            DEPLOYMENT_NAME=backend-test-deployment

            kubectl -n $NAMESPACE set image deployment/$DEPLOYMENT_NAME backend=${GHCR_REPO}:${BUILD_TAG} --record
            kubectl -n $NAMESPACE rollout status deployment/$DEPLOYMENT_NAME --timeout=120s
          '''
        }
      }
    }
  }

  post {
    always { sh 'docker system prune -af || true' }
    success { echo "Pipeline finalizado correctamente. Imagen tag: ${BUILD_TAG}" }
    failure { echo "Pipeline FALLÓ. Revisar logs." }
  }
}
