# Step 2: Declarative Pipeline as Code (Jenkinsfile)

## Goal
Move from UI-configured Freestyle jobs to a version-controlled `Jenkinsfile` — the modern way to define Jenkins pipelines.

## What You'll Do

### 2.1 Create a Jenkinsfile
Add a `Jenkinsfile` to the root of your repo:

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'pip install -r requirements.txt'
            }
        }

        stage('Lint') {
            steps {
                sh 'flake8 app/'
            }
        }

        stage('Test') {
            steps {
                sh 'pytest app/tests/ --junitxml=results.xml'
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
```

### 2.2 Create a Pipeline Job in Jenkins
1. **New Item** → name it `flask-api-pipeline` → select **Pipeline**
2. **Pipeline section** → Definition: **Pipeline script from SCM**
3. SCM: **Git** → paste your repo URL
4. Script Path: `Jenkinsfile`
5. **Save** and **Build Now**

### 2.3 See Test Results in the UI
- The `junit 'results.xml'` post-action publishes test results
- Click on a build → **Test Result** tab → see pass/fail per test
- Track test trends over multiple builds

### 2.4 Break Things on Purpose
- Add a failing test → see the Test stage go red, but Lint stays green
- Add a flake8 violation (e.g., `import os` unused) → Lint fails
- Observe: each stage is independent, failures are isolated and visible

## What You'll Learn
- **Declarative vs. Scripted pipelines:**
  - Declarative: structured, opinionated, uses `pipeline {}` block — use this by default
  - Scripted: freeform Groovy, uses `node {}` block — for complex logic
- **Jenkinsfile syntax:** `pipeline`, `agent`, `stages`, `stage`, `steps`, `post`
- **`post` conditions:** `always`, `success`, `failure`, `unstable`, `changed`
- **JUnit plugin:** renders test results in the Jenkins UI with trends
- **Why pipeline-as-code matters:** versioned in Git, reviewable in PRs, portable across Jenkins instances

## Declarative Pipeline Structure

```
pipeline {
    agent       → WHERE to run (any, docker, label)
    environment → env vars available to all stages
    stages {
        stage('Name') {
            steps {   → WHAT to run
                sh '...'
            }
        }
    }
    post {      → AFTER all stages
        always / success / failure / unstable
    }
}
```

## Files to Create/Modify
| File | Action | Purpose |
|------|--------|---------|
| `Jenkinsfile` | Create | Declarative pipeline definition |
| `app/.flake8` | Create | Flake8 linter configuration |

### app/.flake8
```ini
[flake8]
max-line-length = 120
exclude = __pycache__,.git
```

## Verification
- [ ] Pipeline job runs all 4 stages and shows the stage view in Jenkins
- [ ] Test results appear in the **Test Result** tab
- [ ] A failing test turns the Test stage red but doesn't affect earlier stages
- [ ] A lint violation turns the Lint stage red
- [ ] Jenkinsfile changes are tracked in git history
