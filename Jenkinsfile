pipeline {
    agent none

    environment {
        APP_NAME    = 'flask-api'
        APP_VERSION = "${env.BUILD_NUMBER}"
        REGISTRY    = 'docker.io/rajsambasivan'
    }

    parameters {
        choice(name: 'DEPLOY_TARGET', choices: ['staging', 'production'], description: 'Deployment target')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip test stage')
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
                    when { expression { !params.SKIP_TESTS } }
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

        stage('Deploy to Staging') {
            when {
                beforeAgent true
                branch 'develop'
            }
            agent any
            steps {
                unstash 'source'
                sh './deploy.sh staging'
            }
        }

        stage('Deploy to Production') {
            when {
                beforeAgent true
                branch 'main'
            }
            agent any
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                unstash 'source'
                sh './deploy.sh production'
            }
        }
    }

    post {
        always {
            node('') {
                script {
                    try {
                        unstash 'test-results'
                        junit 'results.xml'
                        archiveArtifacts artifacts: 'coverage-report/**', fingerprint: true
                    } catch (e) {
                        echo "No test results to archive (tests may have been skipped)"
                    }
                    // Save console log as artifact with branch name
                    sh "curl -s ${env.BUILD_URL}consoleText > console-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.txt"
                    archiveArtifacts artifacts: "console-${env.BUILD_NUMBER}-${env.BRANCH_NAME}.txt"
                }
            }
        }
        success {
            echo 'All stages passed!'
        }
        failure {
            echo 'Pipeline failed — check the stage that went red.'
            // Uncomment after configuring Extended E-mail in Jenkins:
            // emailext(
            //     subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            //     body: "Check: ${env.BUILD_URL}",
            //     to: 'you@example.com'
            // )
        }
    }
}
