# Step 5: Shared Libraries, Parallel Stages & Full CD

## Goal
DRY up pipelines with shared libraries, speed up builds with parallel stages, add security scanning, and visualize the full pipeline with Blue Ocean.

## What You'll Do

### 5.1 Create a Jenkins Shared Library
A shared library is a separate Git repo (or directory) containing reusable pipeline code.

**Directory structure:**
```
jenkins-shared-library/
  vars/
    buildDockerImage.groovy    # Custom step: buildDockerImage(imageName, tag)
    deployTo.groovy            # Custom step: deployTo(environment)
    notifySlack.groovy         # Custom step: notifySlack(status, channel)
```

#### vars/buildDockerImage.groovy
```groovy
def call(Map config = [:]) {
    def imageName = config.imageName ?: error("imageName is required")
    def tag = config.tag ?: env.BUILD_NUMBER
    def dockerfile = config.dockerfile ?: './app/Dockerfile'
    def context = config.context ?: './app'

    echo "Building Docker image: ${imageName}:${tag}"
    sh "docker build -t ${imageName}:${tag} -f ${dockerfile} ${context}"
    return "${imageName}:${tag}"
}
```

#### vars/deployTo.groovy
```groovy
def call(String environment) {
    echo "Deploying to ${environment}..."
    sh "./deploy.sh ${environment}"
    echo "Deployment to ${environment} complete."
}
```

#### vars/notifySlack.groovy
```groovy
def call(Map config = [:]) {
    def status = config.status ?: 'UNKNOWN'
    def channel = config.channel ?: '#builds'
    def color = status == 'SUCCESS' ? 'good' : 'danger'
    def message = "${env.JOB_NAME} #${env.BUILD_NUMBER}: ${status} (<${env.BUILD_URL}|Open>)"

    // Requires the Slack Notification plugin
    slackSend(channel: channel, color: color, message: message)
}
```

### 5.2 Configure the Shared Library in Jenkins
1. **Manage Jenkins** → **System** → **Global Pipeline Libraries**
2. Add a library:
   - Name: `flask-api-shared`
   - Default version: `main`
   - Retrieval method: **Modern SCM** → Git → repo URL of the shared library
3. In the Jenkinsfile, import with: `@Library('flask-api-shared') _`

### 5.3 Add Parallel Stages
Run lint, test, and security scan simultaneously to cut build time:

```groovy
stage('Quality Gates') {
    parallel {
        stage('Lint') {
            agent { docker { image 'python:3.11-slim' } }
            steps {
                sh 'pip install flake8 && flake8 app/'
            }
        }
        stage('Test') {
            agent { docker { image 'python:3.11-slim' } }
            steps {
                sh 'pip install -r requirements.txt && pytest app/tests/ --junitxml=results.xml'
            }
            post {
                always { junit 'results.xml' }
            }
        }
        stage('Security Scan') {
            agent { docker { image 'python:3.11-slim' } }
            steps {
                sh 'pip install bandit && bandit -r app/ -f json -o bandit-report.json || true'
            }
            post {
                always { archiveArtifacts artifacts: 'bandit-report.json', allowEmptyArchive: true }
            }
        }
    }
}
```

### 5.4 Complete Jenkinsfile Using Shared Library
```groovy
@Library('flask-api-shared') _

pipeline {
    agent none  // Each stage defines its own agent

    environment {
        APP_NAME = 'flask-api'
        REGISTRY = 'docker.io/yourusername'
    }

    stages {
        stage('Quality Gates') {
            parallel {
                stage('Lint') {
                    agent { docker { image 'python:3.11-slim' } }
                    steps { sh 'pip install flake8 && flake8 app/' }
                }
                stage('Test') {
                    agent { docker { image 'python:3.11-slim' } }
                    steps {
                        sh 'pip install -r requirements.txt && pytest app/tests/ --junitxml=results.xml'
                    }
                    post { always { junit 'results.xml' } }
                }
                stage('Security Scan') {
                    agent { docker { image 'python:3.11-slim' } }
                    steps {
                        sh 'pip install bandit && bandit -r app/ -f json -o bandit-report.json || true'
                    }
                    post { always { archiveArtifacts 'bandit-report.json' } }
                }
            }
        }

        stage('Build Image') {
            agent any
            steps {
                script {
                    buildDockerImage(imageName: "${REGISTRY}/${APP_NAME}", tag: "${BUILD_NUMBER}")
                }
            }
        }

        stage('Push Image') {
            agent any
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                    sh "docker push ${REGISTRY}/${APP_NAME}:${BUILD_NUMBER}"
                }
            }
        }

        stage('Deploy Staging') {
            when { branch 'develop' }
            agent any
            steps {
                deployTo('staging')
            }
        }

        stage('Deploy Production') {
            when { branch 'main' }
            agent none
            steps {
                input message: 'Deploy to production?', ok: 'Ship it!'
                node('') {
                    deployTo('production')
                }
            }
        }
    }

    post {
        success { notifySlack(status: 'SUCCESS') }
        failure { notifySlack(status: 'FAILURE') }
    }
}
```

### 5.5 Install Blue Ocean
1. **Manage Jenkins** → **Plugins** → **Available** → search "Blue Ocean" → Install
2. Access at: `http://localhost:8080/blue`
3. Blue Ocean gives you:
   - Visual pipeline editor
   - Beautiful stage visualization with parallel branches
   - Per-stage logs
   - GitHub/Git integration

## What You'll Learn
- **Shared Libraries:** reusable pipeline code across multiple repos/projects
  - `vars/` directory: custom steps callable by name
  - `src/` directory: helper classes (for advanced use)
  - `resources/` directory: non-Groovy files
- **Parallel execution:** multiple stages run simultaneously, reducing total build time
- **`agent none`:** no executor allocated at the pipeline level — each stage manages its own
- **Security scanning:** Bandit for Python static analysis (catches common security issues)
- **Blue Ocean:** modern UI for pipeline visualization

## Shared Library Structure Reference

```
jenkins-shared-library/
  vars/                        # Custom pipeline steps
    myStep.groovy              # Called as: myStep()
    myStep.txt                 # Help text shown in Pipeline Syntax
  src/                         # Helper Groovy classes
    org/example/Utils.groovy   # import org.example.Utils
  resources/                   # Non-Groovy files
    config.json                # Loaded with libraryResource('config.json')
```

## Files to Create/Modify
| File | Action | Purpose |
|------|--------|---------|
| `jenkins-shared-library/vars/buildDockerImage.groovy` | Create | Reusable Docker build step |
| `jenkins-shared-library/vars/deployTo.groovy` | Create | Reusable deploy step |
| `jenkins-shared-library/vars/notifySlack.groovy` | Create | Reusable Slack notification step |
| `Jenkinsfile` | Update | Final version with shared lib + parallel |

## Verification
- [ ] Parallel stages (Lint, Test, Security) run simultaneously in the stage view
- [ ] Build time is shorter than running them sequentially
- [ ] Shared library steps (`buildDockerImage`, `deployTo`) work from the Jenkinsfile
- [ ] Bandit security report is archived as an artifact
- [ ] Blue Ocean shows the full pipeline with parallel branches visually
- [ ] The complete flow works: quality gates → build → push → stage/approve → prod
- [ ] Slack (or email) notification fires on success and failure
