pipeline {
  agent any

  environment {
    DOCKER_CREDS = credentials('docker-hub-credentials')
  }

  stages {
    stage('Build') {
      agent any
      steps {
        sh '''#!/bin/bash
          python3.9 -m venv venv
          source venv/bin/activate
          pip install pip --upgrade
          pip install -r backend/requirements.txt
        '''
      }
    }

    stage('Test') {
      agent any
      steps {
        sh '''#!/bin/bash
        source venv/bin/activate
        pip install pytest-django
        python manage.py makemigrations
        python manage.py migrate
        pytest backend/account/tests.py --verbose --junit-xml test-reports/results.xml
        '''
      }
    }

    stage('Cleanup') {
      agent { label 'build-node' }
      steps {
        sh '''
          echo "Performing in-pipeline cleanup after Test..."
          docker system prune -f
          
          # Safer git clean that preserves terraform state
          git clean -ffdx -e "*.tfstate*" -e ".terraform/*"
        '''
      }
    }

    stage('Build & Push Images') {
      agent { label 'build-node' }
      steps {
        sh 'echo ${DOCKER_CREDS_PSW} | docker login -u ${DOCKER_CREDS_USR} --password-stdin'
        
        // Build and push backend
        sh '''
          docker build -t tjwkura5/ecommerce_back:latest -f Dockerfile.backend .
          docker push tjwkura5/ecommerce_back:latest
        '''
        
        // Build and push frontend
        sh '''
          docker build -t tjwkura5/ecommerce_front:latest -f Dockerfile.frontend .
          docker push tjwkura5/ecommerce_front:latest
        '''
      }
    }

    stage('Infrastructure') {
      agent { label 'build-node' }
      steps {
        dir('Terraform') {
          sh '''
            terraform init
            terraform apply -auto-approve \
              -var="dockerhub_username=${DOCKER_CREDS_USR}" \
              -var="dockerhub_password=${DOCKER_CREDS_PSW}"
          '''
        }
      }
    }

    // Finalize Stage (Replaces post block)
    stage('Finalize') {
      agent { label 'build-node' }
      steps {
        sh '''
          echo "Performing final cleanup tasks..."
          docker logout
          docker system prune -f
        '''
      }
    }
  }
}
