pipeline {
    agent any

    environment {
        SONARQUBE = 'sonarcloud'  // SonarCloud service name
        SCA_TOOL = 'snyk'         // Snyk for Software Composition Analysis (SCA)
        DOCKER_IMAGE = 'springboot-petclinic'  // Docker image name
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Application') {
            steps {
                script {
                    echo 'Building the Java application...'
                    sh 'mvn clean install'  // Build using Maven
                }
            }
        }

        stage('Static Code Analysis (SonarCloud)') {
            steps {
                script {
                    echo 'Running SonarCloud static code analysis...'
                    withCredentials([string(credentialsId: 'sonarcloud-token', variable: 'SONAR_TOKEN')]) {
                        sh "mvn sonar:sonar -Dsonar.host.url=${SONARQUBE} -Dsonar.login=${SONAR_TOKEN}"  // SonarCloud analysis
                    }
                }
            }
        }

        stage('Software Composition Analysis (Snyk)') {
            steps {
                script {
                    echo 'Running Snyk vulnerability scan...'
                    withCredentials([string(credentialsId: 'snyk-api-token', variable: 'SNYK_TOKEN')]) {
                        sh 'snyk test --all-projects --token=$SNYK_TOKEN'  // Dependency vulnerability scan with Snyk
                    }
                }
            }
        }

        stage('Unit Tests') {
            steps {
                script {
                    echo 'Running unit tests...'
                    sh 'mvn test'  // Running tests
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    withCredentials([string(credentialsId: 'docker-hub-credentials', variable: 'DOCKER_HUB_CREDENTIALS')]) {
                        sh 'docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .'  // Docker build
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo 'Pushing Docker image to Docker Hub...'
                    withCredentials([string(credentialsId: 'docker-hub-credentials', variable: 'DOCKER_HUB_CREDENTIALS')]) {
                        sh 'docker login -u $DOCKER_HUB_CREDENTIALS_USR -p $DOCKER_HUB_CREDENTIALS_PSW'  // Docker login
                        sh 'docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}'  // Push Docker image to registry
                    }
                }
            }
        }

        stage('Deploy to Staging (Kubernetes)') {
            steps {
                script {
                    echo 'Deploying to Kubernetes staging...'
                    withCredentials([file(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG_FILE')]) {
                        sh "kubectl --kubeconfig=$KUBECONFIG_FILE set image deployment/my-deployment my-container=${DOCKER_IMAGE}:${BUILD_NUMBER} --namespace=staging"  // Kubernetes deployment
                    }
                }
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'  // Only deploy to production on 'main' branch
            }
            steps {
                script {
                    echo 'Deploying to Kubernetes production...'
                    withCredentials([file(credentialsId: 'kubeconfig-credentials', variable: 'KUBECONFIG_FILE')]) {
                        sh "kubectl --kubeconfig=$KUBECONFIG_FILE set image deployment/my-deployment my-container=${DOCKER_IMAGE}:${BUILD_NUMBER} --namespace=production"  // Kubernetes deployment
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline successfully completed!'
            slackSend(channel: '#devops', message: "Build ${BUILD_NUMBER} succeeded!")
        }
        failure {
            echo 'Pipeline failed!'
            slackSend(channel: '#devops', message: "Build ${BUILD_NUMBER} failed!")
        }
    }
}
