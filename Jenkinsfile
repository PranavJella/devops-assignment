pipeline {

    agent any

    environment {
        FRONTEND_IMAGE = "pranavjella2001/blog-frontend"
        BACKEND_IMAGE  = "pranavjella2001/blog-backend"
        TAG = "latest"
        APP_SERVER = "10.0.2.216"
    }

    stages {

        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh '''
                    docker build -t $FRONTEND_IMAGE:$TAG ./frontend
                '''
            }
        }

        stage('Build Backend Image') {
            steps {
                sh '''
                    docker build -t $BACKEND_IMAGE:$TAG ./backend
                '''
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('Push Images') {
            steps {
                sh '''
                    docker push $FRONTEND_IMAGE:$TAG
                    docker push $BACKEND_IMAGE:$TAG
                '''
            }
        }

        stage('Deploy to Application Server') {
            steps {
                sshagent(credentials: ['app-server']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@$APP_SERVER '
                            docker pull $FRONTEND_IMAGE:$TAG
                            docker pull $BACKEND_IMAGE:$TAG

                            docker stop frontend || true
                            docker rm frontend || true

                            docker stop backend || true
                            docker rm backend || true

                            docker run -d --name frontend -p 80:80 $FRONTEND_IMAGE:$TAG

                            docker run -d --name backend -p 5000:5000 $BACKEND_IMAGE:$TAG
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Application deployed successfully."
        }

        failure {
            echo "Pipeline failed."
        }
    }
}