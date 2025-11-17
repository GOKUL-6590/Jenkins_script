pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')   // Jenkins credentials ID
        IMAGE_NAME = "gokul/myapp"
        SSH_SERVER = "ubuntu@192.168.1.10"
    }

    stages {

        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/yourname/yourrepo.git'
            }
        }

        stage('Build Project') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${IMAGE_NAME}:latest .
                """
            }
        }

        stage('Login to Docker Hub & Push Image') {
            steps {
                sh """
                echo ${DOCKERHUB_CREDENTIALS_PSW} | docker login -u ${DOCKERHUB_CREDENTIALS_USR} --password-stdin
                docker push ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Deploy to Server') {
            steps {
                sh """
                ssh -o StrictHostKeyChecking=no ${SSH_SERVER} '
                    docker pull ${IMAGE_NAME}:latest &&
                    docker stop myapp || true &&
                    docker rm myapp || true &&
                    docker run -d --name myapp -p 8080:8080 ${IMAGE_NAME}:latest
                '
                """
            }
        }
    }

    post {
        success {
            echo "Deployment Successful!"
        }
        failure {
            echo "Build Failed!"
        }
    }
}
