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

        //stage('Build & Compile') {
        //    agent {
        //        docker {
        //            image 'maven:3.9.3-eclipse-temurin-17'
        //            args '-v $HOME/.m2:/root/.m2'
        //        }
        //    }
        //    steps {
        //        sh 'mvn clean verify -DskipTests -Dcheckstyle.skip=true'  // ✅ Compiles project and generates classes
        //    }
        //}

        //stage('SonarQube Analysis') {
        //    agent {
        //        docker {
        //            image 'sonarsource/sonar-scanner-cli:latest'
        //            args '--user root -v $PWD:/usr/src'
        //        }
        //    }
        //    steps {
        //        sh """
        //        sonar-scanner \
        //            -Dsonar.projectKey=${PROJECT_KEY} \
        //            -Dsonar.organization=${ORGANIZATION} \
        //            -Dsonar.host.url=${SONAR_HOST_URL} \
        //            -Dsonar.login=${SONAR_LOGIN} \
        //            -Dsonar.sources=src/main/java \
        //            -Dsonar.java.binaries=target/classes  # ✅ Pass compiled classes path
        //        """
        //    }
        //}

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

        //stage('Snyk Security Scan') {
        //    agent {
        //        docker {
        //            image 'maven:3.8.6-openjdk-11'  // Use Maven container
        //            args '--user root -v /var/run/docker.sock:/var/run/docker.sock -v $PWD:/project -w /project'
        //        }
        //    }
        //    steps {
        //        script {
        //            withCredentials([string(credentialsId: 'snyk-id', variable: 'SNYK_TOKEN')]) {
        //                // Install Snyk CLI inside the Maven container
        //                sh 'curl -Lo /usr/local/bin/snyk https://github.com/snyk/snyk/releases/latest/download/snyk-linux && chmod +x /usr/local/bin/snyk'
        //
        //                // Authenticate Snyk
        //                sh 'snyk auth $SNYK_TOKEN'
        //
        //                // Run Snyk Test on Source Code
        //                sh 'snyk test || true'
        //
        //                // Run Snyk Test on Docker Image
        //                sh 'snyk test --docker ${DOCKER_IMAGE}:${BUILD_NUMBER} || true'
        //            }
        //        }
        //    }
        //}

        //stage('Trivy Scan') {
        //    agent {
        //        docker {
        //            image 'aquasec/trivy:latest'  // Use Trivy as the agent
        //            args '--user root -v /var/run/docker.sock:/var/run/docker.sock --entrypoint=""'
        //        }
        //    }
        //    steps {
        //        script {
        //            // Run Trivy scan on the Docker image
        //            sh 'trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${BUILD_NUMBER}'
        //        }
        //    }
        //}

        stage('Deploy to Kubernetes') {
            agent {
                docker {
                    image 'bitnami/kubectl:latest'  // Use a prebuilt kubectl image
                    args '--entrypoint= -u root -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.kube:/root/.kube'
                }
            }
            environment {
                KUBECONFIG = "/root/.kube/config"  // Ensure kubectl uses the correct config
            }
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig-id', variable: 'KUBECONFIG_FILE')]) {
                        // Create the .kube directory inside the container's /root folder
                        sh '''
                            mkdir -p /root/.kube
                            cp $KUBECONFIG_FILE /root/.kube/config
                            chmod 600 /root/.kube/config
                        '''
                        
                        // Deploy updated image to Kubernetes
                        sh '''
                            kubectl set image deployment/${DEPLOYMENT_NAME} ${DOCKER_IMAGE}=${DOCKER_IMAGE}:${BUILD_NUMBER}
                            kubectl rollout restart deployment/${DEPLOYMENT_NAME}
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
}
