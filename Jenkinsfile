pipeline {
    agent any

    environment {
        // Replace these with your actual Jenkins tool names
        JAVA_HOME = tool name: 'OpenJDK 17', type: 'jdk'    // <-- Change 'OpenJDK 17' to your JDK name
        MAVEN_HOME = tool name: 'Maven 3.8.8', type: 'maven' // <-- Change to your Maven name
        PATH = "${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${env.PATH}"
        SONAR_PROJECT_KEY = "puzzle-game-webapp"
        SONAR_HOST_URL = "http://34.202.231.86:9000"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                git(
                    url: 'https://github.com/priya1198/puzzle-game-java-jenkins.git',
                    branch: 'main',
                    credentialsId: 'git'
                )
                script {
                    echo "Checked out commit: ${GIT_COMMIT}"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_AUTH_TOKEN')]) {
                    sh """
                        mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.login=${SONAR_AUTH_TOKEN}
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
                        curl -v -u $NEXUS_USER:$NEXUS_PASS --upload-file target/puzzle-game-webapp.war \
                        http://your-nexus-repo/repository/maven-releases/puzzle-game-webapp.war
                    """
                }
            }
        }

        stage('Prepare WAR for Docker') {
            steps {
                sh 'cp target/puzzle-game-webapp.war docker/'
            }
        }

        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        docker build -t puzzle-game-webapp:latest docker/
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push puzzle-game-webapp:latest
                    """
                }
            }
        }

        stage('Deploy on EC2 via SSH') {
            steps {
                sshagent(['ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@your-ec2-ip '
                            docker pull puzzle-game-webapp:latest &&
                            docker stop puzzle-game-webapp || true &&
                            docker rm puzzle-game-webapp || true &&
                            docker run -d --name puzzle-game-webapp -p 8080:8080 puzzle-game-webapp:latest
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "PIPELINE SUCCEEDED ✅"
        }
        failure {
            echo "PIPELINE FAILED ❌"
        }
    }
}
