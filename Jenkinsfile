pipeline {
    agent any

    environment {
        JDK_NAME = 'JDK17'              
        MAVEN_NAME = 'maven'            
        NEXUS_CREDENTIALS = 'nexus'     
        DOCKER_CREDENTIALS = 'docker'   
        TOMCAT_CREDENTIALS = 'tomcat'   
        SONAR_AUTH_TOKEN = 'sonar-token'
        SONAR_HOST = 'http://34.202.231.86:9000' 
        GIT_CREDENTIALS = 'git'         
        SSH_CREDENTIALS = 'ssh'         
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git branch: 'main',
                    credentialsId: env.GIT_CREDENTIALS,
                    url: 'https://github.com/priya1198/puzzle-game-java-jenkins.git'
                script {
                    echo "Checked out commit: ${sh(script: 'git rev-parse HEAD', returnStdout: true).trim()}"
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
                withCredentials([string(credentialsId: env.SONAR_AUTH_TOKEN, variable: 'SONAR_TOKEN')]) {
                    sh """
                        mvn org.sonarsource.scanner.maven:sonar-maven-plugin:4.0.0.4121:sonar \
                            -Dsonar.host.url=${SONAR_HOST} \
                            -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo "Quality gate stage can be implemented if SonarQube webhook is used."
            }
        }

        stage('Build WAR') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Upload WAR to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.NEXUS_CREDENTIALS, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    script {
                        def warFile = sh(script: "ls target/*.war", returnStdout: true).trim()
                        def warFileName = warFile.tokenize('/').last()

                        sh """
                            curl -v -u $NEXUS_USER:$NEXUS_PASS --upload-file ${warFile} \
                            http://34.202.231.86:8081/repository/maven-releases/com/example/puzzle-game-webapp/1.0/${warFileName}
                        """
                    }
                }
            }
        }

        stage('Prepare Docker Context') {
            steps {
                // Copy WAR to root as ROOT.war because Dockerfile expects it here
                sh 'cp target/*.war ROOT.war'
            }
        }

        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    // Build from repo root where Dockerfile lives
                    sh 'docker build -t your-docker-repo/puzzle-game:latest .'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
                    sh 'docker push your-docker-repo/puzzle-game:latest'
                }
            }
        }

        stage('Deploy on EC2 via SSH') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: env.SSH_CREDENTIALS, keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        ssh -i $SSH_KEY ubuntu@your-ec2-ip \
                        "docker pull your-docker-repo/puzzle-game:latest && \
                         docker-compose -f /path/to/docker-compose.yml up -d"
                    """
                }
            }
        }
    }

    post {
        success { echo "PIPELINE SUCCESS ✅" }
        failure { echo "PIPELINE FAILED ❌" }
    }
}
