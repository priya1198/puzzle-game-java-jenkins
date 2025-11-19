pipeline {
    agent any

    environment {
        // Replace these with the exact tool names configured in Jenkins Global Tool Configuration
        JDK_NAME = 'jdk-17'      // <-- Make sure this matches your JDK installation in Jenkins
        MAVEN_NAME = 'Maven 3.8' // <-- Make sure this matches your Maven installation in Jenkins

        // SonarQube token (from Jenkins Credentials)
        SONAR_AUTH_TOKEN = credentials('sonar-token')

        // Nexus repository credentials
        NEXUS_CREDENTIALS = credentials('nexus')

        // Docker registry credentials
        DOCKER_CREDENTIALS = credentials('docker')

        // Git credentials
        GIT_CREDENTIALS = credentials('git')

        // Tomcat credentials
        TOMCAT_CREDENTIALS = credentials('tomcat')

        // SSH credentials for EC2
        SSH_CREDENTIALS = 'ssh'

        // Docker image variables
        DOCKER_IMAGE = 'puzzle-game'
        DOCKER_TAG = 'latest'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/priya1198/puzzle-game-java-jenkins.git',
                    credentialsId: 'git'
                script {
                    echo "Checked out commit: ${env.GIT_COMMIT}"
                }
            }
        }

        stage('Tool Setup') {
            steps {
                script {
                    env.JAVA_HOME = tool name: env.JDK_NAME, type: 'jdk'
                    env.PATH = "${env.JAVA_HOME}/bin:${env.PATH}"
                    env.MAVEN_HOME = tool name: env.MAVEN_NAME, type: 'maven'
                    env.PATH = "${env.MAVEN_HOME}/bin:${env.PATH}"
                    sh 'java -version'
                    sh 'mvn -version'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withEnv(["SONAR_TOKEN=${env.SONAR_AUTH_TOKEN}"]) {
                    sh """
                        mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=puzzle-game-webapp \
                            -Dsonar.host.url=http://34.202.231.86:9000 \
                            -Dsonar.login=$SONAR_TOKEN
                    """
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
                sh 'mvn clean package'
            }
        }

        stage('Upload WAR to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                        curl -v -u $NEXUS_USER:$NEXUS_PASS --upload-file target/puzzle-game.war \
                        http://your-nexus-repo/repository/maven-releases/puzzle-game.war
                    """
                }
            }
        }

        stage('Prepare WAR for Docker') {
            steps {
                sh 'cp target/puzzle-game.war docker/'
            }
        }

        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        docker build -t $DOCKER_IMAGE:$DOCKER_TAG docker/
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push $DOCKER_IMAGE:$DOCKER_TAG
                    """
                }
            }
        }

        stage('Deploy on EC2 via SSH') {
            steps {
                sshagent([env.SSH_CREDENTIALS]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@<EC2_PUBLIC_IP> '
                        docker pull $DOCKER_IMAGE:$DOCKER_TAG &&
                        docker stop puzzle-game || true &&
                        docker rm puzzle-game || true &&
                        docker run -d --name puzzle-game -p 8080:8080 $DOCKER_IMAGE:$DOCKER_TAG
                        '
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
