pipeline {
    agent any

    environment {
        // Tool names configured in Jenkins
        JAVA_HOME = tool name: 'jdk', type: 'jdk'
        MAVEN_HOME = tool name: 'maven', type: 'maven'
        PATH = "${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${env.PATH}"
    }

    stages {

        stage('Checkout SCM') {
            steps {
                echo "Checking out code..."
                checkout scm
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_AUTH_TOKEN')]) {
                    sh """
                        echo "Running SonarQube analysis..."
                        mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=puzzle-game-webapp \
                        -Dsonar.host.url=http://34.202.231.86:9000 \
                        -Dsonar.login=${SONAR_AUTH_TOKEN}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo "Waiting for SonarQube Quality Gate..."
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build WAR') {
            steps {
                echo "Building WAR file..."
                sh "mvn clean package"
            }
        }

        stage('Upload WAR to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                        echo "Uploading WAR to Nexus..."
                        curl -v -u ${NEXUS_USER}:${NEXUS_PASS} --upload-file target/puzzle-game.war \
                        http://nexus-repo-url/repository/maven-releases/puzzle-game.war
                    """
                }
            }
        }

        stage('Prepare WAR for Docker') {
            steps {
                sh """
                    echo "Copying WAR for Docker..."
                    cp target/puzzle-game.war docker/
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo "Logging into Docker..."
                        echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin
                        docker build -t priyapranaya/puzzle-game:latest docker/
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh "docker push priyapranaya/puzzle-game:latest"
            }
        }

        stage('Deploy on EC2 via SSH') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ssh', keyFileVariable: 'EC2_KEY', usernameVariable: 'EC2_USER')]) {
                    sh """
                        echo "Deploying WAR on EC2..."
                        scp -i ${EC2_KEY} docker/puzzle-game.war ${EC2_USER}@your.ec2.ip:/opt/tomcat/webapps/
                        ssh -i ${EC2_KEY} ${EC2_USER}@your.ec2.ip 'sudo systemctl restart tomcat'
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
