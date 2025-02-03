pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-id')   
        KUBECONFIG_CRED = credentials('kubeconfig-id')                    
        DOCKER_IMAGE = "prayags/springboot-petclinic"
        SONAR_SCANNER_HOME = '/opt/sonar-scanner/sonar-scanner-6.2.1.4610-linux-x64'
        SONAR_HOST_URL = 'https://sonarcloud.io'
        SONAR_LOGIN = credentials('sonarcloud-id') // Sonar login token
        PROJECT_KEY = 'prayag-sangode_springboot-petclinic'
        ORGANIZATION = 'prayag-sangode'
        PATH = "${env.PATH}:${SONAR_SCANNER_HOME}/bin"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm  // Pull the source code from the repository
            }
        }

        stage('Build & SonarQube Analysis') {
            steps {
                script {
                    // Run SonarQube scan using sonar-scanner-cli Docker image
                    docker.image('sonarsource/sonar-scanner-cli').inside {
                        sh """
                        # Ensure cache directory has the correct permissions
                        mkdir -p /opt/sonar-scanner/.sonar/cache
                        chmod -R 777 /opt/sonar-scanner/.sonar

                        sonar-scanner \
                            -Dsonar.projectKey=${env.PROJECT_KEY} \
                            -Dsonar.organization=${env.ORGANIZATION} \
                            -Dsonar.host.url=${env.SONAR_HOST_URL} \
                            -Dsonar.login=${env.SONAR_LOGIN} \
                            -Dsonar.sources=.
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build the Docker image from Dockerfile
                    docker.build("${DOCKER_IMAGE}:${BUILD_NUMBER}") // Docker image name
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
                        sh "docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Snyk Security Scan') {
            steps {
                script {
                    // Scan the Docker image for vulnerabilities using Snyk
                    withCredentials([string(credentialsId: 'snyk-id', variable: 'SNYK_TOKEN')]) {
                        sh 'snyk auth $SNYK_TOKEN'  // Authenticate with Snyk
                        // Run Snyk Test on Source Code
                        sh 'snyk test || true'
                        // Run Snyk Test on Docker Image
                        sh 'snyk test --docker ${DOCKER_IMAGE}:${BUILD_NUMBER} || true'
                    }
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    // Scan the Docker image for vulnerabilities using Trivy
                    sh 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $PWD:/project aquasec/trivy image ${DOCKER_IMAGE}:${BUILD_NUMBER}'  // Run Trivy scan
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
                            kubectl set image deployment/${DOCKER_IMAGE}-deployment ${DOCKER_IMAGE}=${DOCKER_IMAGE}:${BUILD_NUMBER}
                            kubectl rollout restart deployment/${DOCKER_IMAGE}-deployment
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
