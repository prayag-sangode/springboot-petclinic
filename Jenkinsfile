pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-id')   
        KUBECONFIG_FILE = credentials('kubeconfig-id')                    
        DOCKER_IMAGE = "prayags/springboot-petclinic"
        DEPLOYMENT_NAME = "springboot-petclinic"
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

        stage('Build & Compile') {
            steps {
                sh 'docker run --rm -v $PWD:/app -w /app maven:3.9.3-eclipse-temurin-17 mvn clean package -DskipTests -Dcheckstyle.skip=true'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh 'whoami'
                sh 'pwd'
                sh 'ls'
                sh 'ls -l'
        
                // Try only changing permissions instead of ownership
                sh 'chmod -R 777 /var/lib/jenkins/sonar-cache'
        
                sh 'docker run --rm -v $PWD:/app -v /var/lib/jenkins/sonar-cache:/opt/sonar-scanner/.sonar -w /app --user 115:122 sonarsource/sonar-scanner-cli:latest sonar-scanner -Dsonar.projectKey=****-sangode_springboot-petclinic -Dsonar.organization=****-sangode -Dsonar.host.url=https://sonarcloud.io -Dsonar.token=**** -Dsonar.sources=. -Dsonar.java.binaries=target/classes'
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
                        sh 'curl -Lo /usr/local/bin/snyk https://github.com/snyk/snyk/releases/latest/download/snyk-linux && chmod +x /usr/local/bin/snyk'
                        sh 'snyk auth $SNYK_TOKEN'
                        sh 'snyk test || true'
                        sh "snyk test --docker ${DOCKER_IMAGE}:${BUILD_NUMBER} || true"
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
