pipeline {
    agent {
        docker {
            image 'python:3.11-slim'
        }
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
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
                sh 'pytest app/tests/ -v --junitxml=results.xml'
            }
        }
    }

    post {
        always {
            junit 'results.xml'
        }
        success {
            echo 'All stages passed!'
        }
        failure {
            echo 'Pipeline failed — check the stage that went red.'
        }
    }
}
