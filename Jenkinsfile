pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = credentials('dockerhub-id')   
        KUBECONFIG_FILE = credentials('kubeconfig-id')                    
        DOCKER_IMAGE = "prayags/springboot-petclinic"
        DEPLOYMENT_NAME = "springboot-petclinic"
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
            agent {
                dockerContainer {
                    image 'maven:3.9.3-eclipse-temurin-17'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                sh 'mvn clean verify -DskipTests -Dcheckstyle.skip=true'
            }
        }

        stage('SonarQube Analysis') {
            agent {
                dockerContainer {
                    image 'sonarsource/sonar-scanner-cli:latest'
                    args '--user root -v $PWD:/usr/src'
                }
            }
            steps {
                sh """
                sonar-scanner \
                    -Dsonar.projectKey=${PROJECT_KEY} \
                    -Dsonar.organization=${ORGANIZATION} \
                    -Dsonar.host.url=${SONAR_HOST_URL} \
                    -Dsonar.login=${SONAR_LOGIN} \
                    -Dsonar.sources=src/main/java \
                    -Dsonar.java.binaries=target/classes
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE}:${BUILD_NUMBER}")
                }
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
            agent {
                dockerContainer {
                    image 'maven:3.8.6-openjdk-11'
                    args '--user root -v /var/run/docker.sock:/var/run/docker.sock -v $PWD:/project -w /project'
                }
            }
            steps {
                script {
                    withCredentials([string(credentialsId: 'snyk-id', variable: 'SNYK_TOKEN')]) {
                        sh 'curl -Lo /usr/local/bin/snyk https://github.com/snyk/snyk/releases/latest/download/snyk-linux && chmod +x /usr/local/bin/snyk'
                        sh 'snyk auth $SNYK_TOKEN'
                        sh 'snyk test || true'
                        sh 'snyk test --docker ${DOCKER_IMAGE}:${BUILD_NUMBER} || true'
                    }
                }
            }
        }

        stage('Trivy Scan') {
            agent {
                dockerContainer {
                    image 'aquasec/trivy:latest'
                    args '--user root -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=""'
                }
            }
            steps {
                script {
                    sh 'trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${BUILD_NUMBER}'
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
