pipeline {
    agent any

    environment {
        ARTIFACT_ID = 'puzzle-game-webapp'
        SONAR_HOST_URL = 'http://34.202.231.86:9000'
    }

    tools {
        maven 'maven'
        jdk 'JDK17'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    echo "Checked out commit: ${env.GIT_COMMIT}"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'SONAR_AUTH_TOKEN', variable: 'SONAR_AUTH_TOKEN')]) {
                    script {
                        def mvnHome = tool 'maven'
                        sh """
                            ${mvnHome}/bin/mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=${ARTIFACT_ID} \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_AUTH_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build WAR') {
            steps {
                script {
                    def mvnHome = tool 'maven'
                    sh "${mvnHome}/bin/mvn clean package"
                }
            }
        }

        stage('Upload WAR to Nexus') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'NEXUS_CREDENTIALS', 
                                     usernameVariable: 'NEXUS_USER', 
                                     passwordVariable: 'NEXUS_PASSWORD')
                ]) {
                    sh """
                        curl -v -u $NEXUS_USER:$NEXUS_PASSWORD --upload-file target/${ARTIFACT_ID}.war \
                        http://nexus.example.com/repository/maven-releases/${ARTIFACT_ID}.war
                    """
                }
            }
        }

        stage('Prepare WAR for Docker') {
            steps {
                sh "cp target/${ARTIFACT_ID}.war docker/"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${ARTIFACT_ID}:latest docker/"
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'DOCKER_CREDENTIALS', 
                                                  usernameVariable: 'DOCKER_USER', 
                                                  passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker tag ${ARTIFACT_ID}:latest mydockerhub/${ARTIFACT_ID}:latest
                        docker push mydockerhub/${ARTIFACT_ID}:latest
                    """
                }
            }
        }

        stage('Deploy on EC2 via SSH') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'EC2_SSH_KEY', 
                                                   keyFileVariable: 'SSH_KEY', 
                                                   usernameVariable: 'SSH_USER')]) {
                    sh """
                        scp -i $SSH_KEY docker/${ARTIFACT_ID}.war $SSH_USER@ec2-instance:/opt/app/
                        ssh -i $SSH_KEY $SSH_USER@ec2-instance 'docker stop ${ARTIFACT_ID} || true && docker rm ${ARTIFACT_ID} || true && docker run -d --name ${ARTIFACT_ID} -p 8080:8080 mydockerhub/${ARTIFACT_ID}:latest'
                    """
                }
            }
        }
    }

    post {
        success {
            echo "PIPELINE SUCCESS ✅"
        }
        failure {
            echo "PIPELINE FAILED ❌"
        }
    }
}
