pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "prayags/springboot-petclinic"
        DEPLOYMENT_NAME = "springboot-petclinic"
        SONAR_HOST_URL = 'https://sonarcloud.io'
        PROJECT_KEY = 'prayag-sangode_springboot-petclinic'
        ORGANIZATION = 'prayag-sangode'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Compile') {
            steps {
                sh 'docker run --rm -v $PWD:/app -w /app maven:3.9.3-eclipse-temurin-17 mvn clean verify -DskipTests -Dcheckstyle.skip=true'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    sh 'chmod -R a+rX .' // Ensure readable files
                    sh """
                    docker run --rm -u $(id -u):$(id -g) -v "\$PWD:/app" -w /app sonarsource/sonar-scanner-cli:latest \
                        sonar-scanner \
                        -Dsonar.projectKey=${PROJECT_KEY} \
                        -Dsonar.organization=${ORGANIZATION} \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.token=\$SONAR_LOGIN \
                        -Dsonar.sources=. \
                        -Dsonar.java.binaries=target/classes \
                        -Dsonar.scm.disabled=true
                    """

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
                        sh 'mkdir -p ~/.local/bin && curl -Lo ~/.local/bin/snyk https://github.com/snyk/snyk/releases/latest/download/snyk-linux && chmod +x ~/.local/bin/snyk'
                        sh 'export PATH=$HOME/.local/bin:$PATH && snyk auth $SNYK_TOKEN'
                        sh 'snyk test || true'
                        sh "snyk test --docker ${DOCKER_IMAGE}:${BUILD_NUMBER} || true"
                    }
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${BUILD_NUMBER} || true"
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
