# Step 4: Multibranch Pipeline, Webhooks & Notifications

## Goal
Automatic pipeline discovery per branch/PR, instant webhook triggers, branch-specific deployment with manual approval gates, and notifications.

## What You'll Do

### 4.1 Create a Multibranch Pipeline
1. **New Item** → name it `flask-api-multibranch` → select **Multibranch Pipeline**
2. **Branch Sources** → **Git** → repo URL
3. **Scan Multibranch Pipeline Triggers** → interval: 1 minute (for testing)
4. **Save** → Jenkins scans the repo and creates a job per branch that has a `Jenkinsfile`

**What happens:** Push a new branch with a Jenkinsfile → Jenkins auto-detects it and runs the pipeline. Delete the branch → Jenkins removes the job.

### 4.2 Set Up Webhooks (replaces poll SCM)
Instead of Jenkins polling every N minutes, the Git server pushes a notification to Jenkins on every commit.

**For GitHub:**
1. Install the **GitHub** plugin in Jenkins
2. In your GitHub repo → **Settings** → **Webhooks** → Add:
   - Payload URL: `http://<your-jenkins>/github-webhook/`
   - Content type: `application/json`
   - Events: **Just the push event** (or Pushes + Pull Requests)
3. In the Multibranch Pipeline config, set the trigger to **GitHub hook trigger**

**For local testing (ngrok):**
```bash
ngrok http 8080
# Use the ngrok URL as your webhook payload URL
```

### 4.3 Add Branch-Specific Behavior
```groovy
pipeline {
    agent { docker { image 'python:3.11-slim' } }

    parameters {
        choice(name: 'DEPLOY_TARGET', choices: ['staging', 'production'], description: 'Deployment target')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip test stage')
    }

    stages {
        stage('Lint')  { steps { sh 'flake8 app/' } }

        stage('Test') {
            when { expression { !params.SKIP_TESTS } }
            steps { sh 'pytest app/tests/ --junitxml=results.xml' }
        }

        stage('Build Image') {
            steps { sh 'docker build -t flask-api:${BUILD_NUMBER} ./app' }
        }

        stage('Deploy to Staging') {
            when { branch 'develop' }
            steps {
                sh './deploy.sh staging'
            }
        }

        stage('Deploy to Production') {
            when { branch 'main' }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                sh './deploy.sh production'
            }
        }
    }

    post {
        always { junit allowEmptyResults: true, testResults: 'results.xml' }
        failure {
            emailext(
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Check: ${env.BUILD_URL}",
                to: 'you@example.com'
            )
        }
    }
}
```

### 4.4 Configure Email Notifications
1. **Manage Jenkins** → **System** → **Extended E-mail Notification**
2. SMTP server: `smtp.gmail.com` (or your mail server)
3. Port: 587, TLS enabled
4. Add SMTP credentials in Jenkins Credentials Store
5. The `emailext` step in `post { failure {} }` sends the notification

### 4.5 Manual Approval Gate
The `input` step in the "Deploy to Production" stage:
- **Pauses the pipeline** and shows a button in the Jenkins UI
- A human must click **Deploy** to continue (or **Abort** to cancel)
- The pipeline holds a build executor while waiting — in production, use `agent none` for the input stage to avoid this

## What You'll Learn
- **Multibranch pipelines:** one job config, automatic per-branch pipeline discovery
- **Webhooks vs. polling:** webhooks are instant and reduce load; polling adds delay
- **`when` directive:** conditional stage execution based on branch, expression, environment
- **`input` step:** manual approval gates for controlled deployments
- **`parameters` block:** parameterized builds with choice, boolean, string inputs
- **Email notifications:** `emailext` plugin for failure/success alerts

## `when` Conditions Reference

| Condition | Example | Meaning |
|-----------|---------|---------|
| `branch` | `when { branch 'main' }` | Only on this branch |
| `expression` | `when { expression { return params.X } }` | Groovy boolean |
| `environment` | `when { environment name: 'ENV', value: 'prod' }` | Env var match |
| `changeset` | `when { changeset '**/*.py' }` | Only if these files changed |
| `not` | `when { not { branch 'main' } }` | Negate a condition |
| `allOf` | `when { allOf { branch 'main'; environment ... } }` | All must match |
| `anyOf` | `when { anyOf { branch 'main'; branch 'develop' } }` | Any must match |

## Files to Create/Modify
| File | Action | Purpose |
|------|--------|---------|
| `Jenkinsfile` | Update | `when`, `input`, `parameters`, `emailext` |
| `deploy.sh` | Create | Simple deployment script |
| `docker-compose.staging.yml` | Create | Staging environment config |
| `docker-compose.prod.yml` | Create | Production environment config |

### deploy.sh
```bash
#!/bin/bash
set -e
TARGET=${1:-staging}
echo "Deploying to ${TARGET}..."
docker compose -f "docker-compose.${TARGET}.yml" up -d
echo "Deployment to ${TARGET} complete."
```

## Verification
- [ ] Multibranch pipeline auto-discovers branches with Jenkinsfiles
- [ ] Creating a new branch triggers a build (via webhook or scan)
- [ ] `develop` branch deploys to staging automatically
- [ ] `main` branch pauses at the approval gate before deploying to production
- [ ] Clicking **Abort** at the approval gate cancels the deploy
- [ ] A failed build sends an email notification
- [ ] Parameterized builds work — you can choose DEPLOY_TARGET from a dropdown
