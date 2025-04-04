pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-id')   
        KUBECONFIG_FILE = credentials('kubeconfig-id')                    
        DOCKER_IMAGE = "prayags/springboot-petclinic"
        DEPLOYMENT_NAME = "springboot-petclinic"
        IMAGE_PULL_SECRET = "dockerhub-secret"
        SONAR_SCANNER_HOME = '/opt/sonar-scanner/sonar-scanner-6.2.1.4610-linux-x64'
        SONAR_HOST_URL = 'https://sonarcloud.io'
        SONAR_LOGIN = credentials('sonarcloud-id')
        PROJECT_KEY = 'prayag-sangode_springboot-petclinic'
        ORGANIZATION = 'prayag-sangode'
        PATH = "${env.PATH}:${SONAR_SCANNER_HOME}/bin"
    }

    stages {  
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Compile') {
            steps {
                sh 'docker run --rm -v $PWD:/app -w /app maven:3.9.3-eclipse-temurin-17 mvn clean package -DskipTests -Dcheckstyle.skip=true'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonarcloud-id', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        docker run --rm \
                            -v $PWD:/app \
                            -v /var/lib/jenkins/sonar-cache:/opt/sonar-scanner/.sonar \
                            -v /var/lib/jenkins/sonar-tmp:/tmp \
                            -w /app --user 115:122 \
                            sonarsource/sonar-scanner-cli:latest sonar-scanner \
                            -Dsonar.projectKey=$PROJECT_KEY \
                            -Dsonar.organization=$ORGANIZATION \
                            -Dsonar.host.url=$SONAR_HOST_URL \
                            -Dsonar.token=$SONAR_TOKEN \
                            -Dsonar.sources=. \
                            -Dsonar.java.binaries=target/classes
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-id', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Snyk Security Scan') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'snyk-id', variable: 'SNYK_TOKEN')]) {
                        sh '''
                            docker run --rm \
                                -e SNYK_TOKEN=$SNYK_TOKEN \
                                -v /var/run/docker.sock:/var/run/docker.sock \
                                snyk/snyk-cli test || true
                            
                            docker run --rm \
                                -e SNYK_TOKEN=$SNYK_TOKEN \
                                -v /var/run/docker.sock:/var/run/docker.sock \
                                snyk/snyk-cli test --docker ${DOCKER_IMAGE}:${BUILD_NUMBER} || true
                        '''
                    }
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withKubeConfig([credentialsId: 'kubeconfig-id', serverUrl: 'https://127.0.0.1:16443']) {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub-id', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            
                            // Create Kubernetes secret for image pull
                            sh '''
                                kubectl delete secret ${IMAGE_PULL_SECRET} --ignore-not-found -n default
                                kubectl create secret docker-registry ${IMAGE_PULL_SECRET} \
                                    --docker-server=https://index.docker.io/v1/ \
                                    --docker-username=${DOCKER_USER} \
                                    --docker-password=${DOCKER_PASS} \
                                    --docker-email=your-email@example.com
                            '''
                            
                            // Update deployment YAML with correct image and secret
                            sh '''
                                sed -i "s|{{IMAGE}}|${DOCKER_IMAGE}:${BUILD_NUMBER}|g" k8s/deployment.yaml
                                sed -i "s|{{APP_NAME}}|${DEPLOYMENT_NAME}|g" k8s/deployment.yaml
                                sed -i "s|{{IMAGE_PULL_SECRET}}|${IMAGE_PULL_SECRET}|g" k8s/deployment.yaml
                                kubectl apply -f k8s/deployment.yaml
                            '''
                        }
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
