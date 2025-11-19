pipeline {
    agent any

    environment {
        NEXUS_URL      = "http://34.202.231.86:8081/repository/maven-releases/"
        DOCKER_REPO    = "priyapranaya/pz-tomcat"
        GROUP_ID       = "com.example"
        ARTIFACT_ID    = "puzzle-game-webapp"
        MVN_OPTS       = "-DskipTests"
        DEPLOY_HOST    = "34.202.231.86"
        CONTAINER_NAME = "tomcat"
    }

    tools {
        maven "maven"
        jdk   "JDK17"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                script {
                    echo "Commit: ${env.GIT_COMMIT ?: 'local'}"
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                        mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=${ARTIFACT_ID}
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
                sh "mvn clean package ${MVN_OPTS}"
            }
        }

        stage('Upload WAR to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    script {
                        def WAR = sh(script: "ls target/*.war | head -n 1", returnStdout: true).trim()
                        if (!fileExists(WAR)) { error "WAR not found at ${WAR}" }

                        def VERSION = sh(
                            script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout",
                            returnStdout: true
                        ).trim()

                        def ARTIFACT_PATH =
                            "${GROUP_ID.replace('.','/')}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.war"

                        echo "Uploading ${WAR} → ${NEXUS_URL}${ARTIFACT_PATH}"

                        sh """
                            curl -v -u ${NEXUS_USER}:${NEXUS_PASS} \
                            --upload-file ${WAR} \
                            "${NEXUS_URL}${ARTIFACT_PATH}"
                        """
                    }
                }
            }
        }

        stage('Prepare WAR for Docker') {
            steps {
                sh """
                    set -e
                    WAR=\$(ls target/*.war | head -n1)
                    if [ -z "\$WAR" ]; then echo "No WAR found"; exit 1; fi

                    cp -f "\$WAR" target/app.war
                    ls -lh target/app.war
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def shortCommit = (env.GIT_COMMIT ?: 'local').take(7)

                    sh """
                        docker build -t ${DOCKER_REPO}:${shortCommit} .
                        docker tag ${DOCKER_REPO}:${shortCommit} ${DOCKER_REPO}:latest
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    script {
                        def shortCommit = (env.GIT_COMMIT ?: 'local').take(7)

                        sh """
                            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                            docker push ${DOCKER_REPO}:${shortCommit}
                            docker push ${DOCKER_REPO}:latest
                        """
                    }
                }
            }
        }

        stage('Deploy on same EC2 via SSH') {
            steps {
                sshagent(['docker-server']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${DEPLOY_HOST} '
                            docker stop ${CONTAINER_NAME} 2>/dev/null || true &&
                            docker rm ${CONTAINER_NAME} 2>/dev/null || true &&
                            docker pull ${DOCKER_REPO}:latest &&
                            docker run -d --name ${CONTAINER_NAME} -p 8080:8080 --restart unless-stopped ${DOCKER_REPO}:latest
                        '
                    """
                }
            }
        }
    }

    post {
        success { echo "PIPELINE SUCCEEDED 🎉" }
        failure { echo "PIPELINE FAILED ❌" }
    }
}
