pipeline {
    agent any

    environment {
        SONARQUBE = 'sonarqube'      
        SCA_TOOL = 'snyk'            
        DOCKER_IMAGE = 'springboot-petclinic'  
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

        stage('Static Code Analysis (SonarQube)') {
            steps {
                script {
                    echo 'Running SonarQube static code analysis...'
                    sh "mvn sonar:sonar -Dsonar.host.url=${SONARQUBE}"  // SonarQube analysis
                }
            }
        }

        stage('Software Composition Analysis (Snyk)') {
            steps {
                script {
                    echo 'Running Snyk vulnerability scan...'
                    sh 'snyk test --all-projects'  // Dependency vulnerability scan with Snyk
                }
            }
        }

        stage('Dynamic Security Testing (OWASP ZAP)') {
            steps {
                script {
                    echo 'Running OWASP ZAP dynamic security tests...'
                    sh 'zap-baseline.py -t http://localhost:8080'  // Assuming the app is running locally
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
                    sh 'docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .'  // Docker build
                }
            }
        }

        stage('Trivy Scan (Container Security)') {
            steps {
                script {
                    echo 'Scanning Docker image with Trivy...'
                    sh 'trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${BUILD_NUMBER}'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    echo 'Pushing Docker image to Docker Hub...'
                    sh 'docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}'  // Push Docker image to registry
                }
            }
        }

        stage('Deploy to Staging') {
            steps {
                script {
                    echo 'Deploying to Kubernetes staging...'
                    sh "kubectl set image deployment/my-deployment my-container=${DOCKER_IMAGE}:${BUILD_NUMBER} --namespace=staging"
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
                    sh "kubectl set image deployment/my-deployment my-container=${DOCKER_IMAGE}:${BUILD_NUMBER} --namespace=production"
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
