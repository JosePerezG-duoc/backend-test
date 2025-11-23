pipeline {
  agent any

  environment {
    DOCKERHUB_REPO = "joseperezg/backend-test"    // reemplaza
    GHCR_REPO = "ghcr.io/JosePerezG-duoc/backend-test"   // reemplaza (o docker.pkg.github.com/...)
    BUILD_TAG = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install dependencies') {
      steps {
        // Ajusta si el proyecto no es Node
        sh 'npm ci'
      }
    }

    stage('Testing') {
      steps {
        // Ajusta según tests del repo
        sh 'npm test'
      }
    }

    stage('Build app') {
      steps {
        // Build de la app (si aplica). Si no, queda en noop.
        sh 'npm run build || echo "no build step"'
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          sh "docker build -t ${DOCKERHUB_REPO}:latest -t ${DOCKERHUB_REPO}:${BUILD_TAG} ."
          sh "docker tag ${DOCKERHUB_REPO}:latest ${GHCR_REPO}:latest"
          sh "docker tag ${DOCKERHUB_REPO}:latest ${GHCR_REPO}:${BUILD_TAG}"
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh 'echo $DH_PASS | docker login -u $DH_USER --password-stdin'
          sh "docker push ${DOCKERHUB_REPO}:latest"
          sh "docker push ${DOCKERHUB_REPO}:${BUILD_TAG}"
          sh 'docker logout'
        }
      }
    }

    stage('Push to GitHub Container Registry') {
      steps {
        withCredentials([string(credentialsId: 'github-packages-token', variable: 'GH_TOKEN')]) {
          // GHCR login (usuario en GH + token)
          sh 'echo $GH_TOKEN | docker login ghcr.io -u TU_GITHUB_USUARIO --password-stdin'
          sh "docker push ${GHCR_REPO}:latest"
          sh "docker push ${GHCR_REPO}:${BUILD_TAG}"
          sh 'docker logout ghcr.io || true'
        }
      }
    }

    stage('Update Kubernetes Deployment') {
      steps {
        withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG=$KUBECONFIG_FILE
            # NAMESPACE: reemplaza por tu namespace (inicial+apellido)
            NAMESPACE=JosePerezG-duoc
            # DEPLOYMENT: nombre del deployment en k8s
            DEPLOYMENT_NAME=backend-test-deployment

            kubectl -n $NAMESPACE set image deployment/$DEPLOYMENT_NAME backend=${GHCR_REPO}:${BUILD_TAG} --record
            # opcional: esperar rollout success
            kubectl -n $NAMESPACE rollout status deployment/$DEPLOYMENT_NAME --timeout=120s
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'docker system prune -af || true'
    }
    success {
      echo "Pipeline finalizado correctamente. Imagen tag: ${BUILD_TAG}"
    }
    failure {
      echo "Pipeline FALLÓ. Revisar logs."
    }
  }
}
