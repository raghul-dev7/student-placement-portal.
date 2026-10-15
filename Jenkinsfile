
pipeline {
    agent any

    parameters {
        choice(
            name: 'APP_MODE',
            choices: ['stable', 'faulty'],
            description: 'Select stable or faulty release'
        )
    }

    environment {
        DOCKERHUB_REPO = 'YOUR_DOCKERHUB_USERNAME/student-placement-portal'
        DEPLOYMENT = 'placement-portal'
        CONTAINER_NAME = 'placement-portal'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                bat 'docker build --build-arg APP_MODE=%APP_MODE% -t %DOCKERHUB_REPO%:%BUILD_NUMBER% .'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    bat 'echo %DOCKER_PASS%| docker login -u "%DOCKER_USER%" --password-stdin'
                    bat 'docker push %DOCKERHUB_REPO%:%BUILD_NUMBER%'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'kuberconfig',
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {
                    withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                        bat 'kubectl apply -f deployment.yaml'
                        bat 'kubectl set image deployment/placement-portal placement-portal=%DOCKERHUB_REPO%:%BUILD_NUMBER%'

                        script {
                            int result = bat(
                                returnStatus: true,
                                script: 'kubectl rollout status deployment/placement-portal --timeout=120s'
                            )

                            if (result != 0) {
                                bat 'kubectl rollout undo deployment/placement-portal'
                                bat 'kubectl rollout status deployment/placement-portal --timeout=120s'
                                error('Faulty release detected. Rollback attempted.')
                            }
                        }
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'kuberconfig',
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {
                    withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                        bat 'kubectl get pods -l app=placement-portal'
                        bat 'kubectl get service placement-portal-service'
                    }
                }
            }
        }
    }
}
