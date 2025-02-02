pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-id')  // DockerHub Credentials
        KUBECONFIG_CRED = credentials('kubeconfig-id')    // Kubernetes Kubeconfig
        SONAR_CRED = credentials('sonarcloud-id')          // SonarCloud Token
        SNYK_CRED = credentials('snyk-id')                 // Snyk Token
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm  // Pull the source code from the repository
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image from Dockerfile
                    docker.build("my-app:${BUILD_NUMBER}") // Docker image name
                }
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    // Log in to Docker Hub
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-id', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        // Push the Docker image
                        sh "docker push my-app:${BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('SonarCloud Scan') {
            steps {
                script {
                    // Perform SonarCloud analysis
                    withCredentials([string(credentialsId: 'sonarcloud-id', variable: 'SONAR_TOKEN')]) {
                        sh '''
                        sonar-scanner \
                        -Dsonar.projectKey=my-app \
                        -Dsonar.organization=my-org \
                        -Dsonar.host.url=https://sonarcloud.io \
                        -Dsonar.login=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Snyk Security Scan') {
            steps {
                script {
                    // Scan the Docker image for vulnerabilities using Snyk
                    withCredentials([string(credentialsId: 'snyk-id', variable: 'SNYK_TOKEN')]) {
                        sh 'npm install -g snyk' // Ensure Snyk CLI is installed
                        sh 'snyk auth $SNYK_TOKEN'  // Authenticate with Snyk
                        sh 'snyk test --all-projects --docker my-app:${BUILD_NUMBER}' // Run Snyk security test
                    }
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    // Scan the Docker image for vulnerabilities using Trivy
                    sh 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $PWD:/project aquasec/trivy my-app:${BUILD_NUMBER}'  // Run Trivy scan
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Set up Kubernetes configuration
                    withCredentials([file(credentialsId: 'kubeconfig-id', variable: 'KUBECONFIG_FILE')]) {
                        sh '''
                        mkdir -p $HOME/.kube
                        cp $KUBECONFIG_FILE $HOME/.kube/config
                        chmod 600 $HOME/.kube/config
                        '''
                        // Deploy the Docker image to Kubernetes
                        sh '''
                        kubectl set image deployment/my-app-deployment my-app=my-app:${BUILD_NUMBER}
                        kubectl rollout restart deployment/my-app-deployment
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
