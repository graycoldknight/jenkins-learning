pipeline {
    agent none

    environment {
        APP_NAME    = 'flask-api'
        APP_VERSION = "${env.BUILD_NUMBER}"
        REGISTRY    = 'docker.io/rajsambasivan'
    }

    stages {
        stage('Lint & Test') {
            agent {
                docker {
                    image 'python:3.11-slim'
                }
            }
            stages {
                stage('Checkout') {
                    steps {
                        checkout scm
                        stash includes: '**', name: 'source'
                    }
                }

                stage('Install Dependencies') {
                    steps {
                        sh 'pip install -r app/requirements.txt'
                    }
                }

                stage('Lint') {
                    steps {
                        sh 'flake8 app/'
                    }
                }

                stage('Test') {
                    steps {
                        sh 'pytest app/tests/ -v --junitxml=results.xml --cov=app --cov-report=html:coverage-report'
                        stash includes: 'results.xml,coverage-report/**', name: 'test-results'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            agent any
            steps {
                unstash 'source'
                sh "docker build -t ${REGISTRY}/${APP_NAME}:${APP_VERSION} ./app"
            }
        }

        stage('Push Docker Image') {
            agent any
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${REGISTRY}/${APP_NAME}:${APP_VERSION}
                    '''
                }
            }
        }
    }

    post {
        always {
            node('') {
                unstash 'test-results'
                junit 'results.xml'
                archiveArtifacts artifacts: 'coverage-report/**', fingerprint: true
            }
        }
        success {
            echo 'All stages passed!'
        }
        failure {
            echo 'Pipeline failed — check the stage that went red.'
        }
    }
}
