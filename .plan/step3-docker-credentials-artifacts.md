# Step 3: Docker Agent, Credentials & Artifacts

## Goal
Run builds inside Docker containers for reproducibility, manage secrets securely, and publish build artifacts.

## What You'll Do

### 3.1 Switch to a Docker Agent
Replace `agent any` with a Docker-based agent so builds run in a clean, isolated container:

```groovy
pipeline {
    agent {
        docker {
            image 'python:3.11-slim'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    // ...
}
```

**Why:** Every build starts from a clean Python 3.11 container — no dependency conflicts, no stale state.

**Prerequisite:** Install the **Docker Pipeline** plugin in Jenkins.

### 3.2 Add Environment Variables
```groovy
environment {
    APP_NAME    = 'flask-api'
    APP_VERSION = "${env.BUILD_NUMBER}"
    REGISTRY    = 'docker.io/yourusername'
}
```

### 3.3 Add a Docker Build Stage
```groovy
stage('Build Docker Image') {
    steps {
        sh "docker build -t ${REGISTRY}/${APP_NAME}:${APP_VERSION} ./app"
    }
}
```

### 3.4 Store Credentials in Jenkins
1. **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. **Add Credentials:**
   - Kind: **Username with password**
   - ID: `dockerhub-creds`
   - Username: your Docker Hub username
   - Password: your Docker Hub token (not your password)

### 3.5 Use Credentials in the Pipeline
```groovy
stage('Push Docker Image') {
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
```

**Key point:** Credentials are masked in console output — Jenkins replaces them with `****`.

### 3.6 Archive Build Artifacts
```groovy
stage('Test') {
    steps {
        sh 'pytest app/tests/ --junitxml=results.xml --cov=app --cov-report=html:coverage-report'
    }
}

post {
    always {
        junit 'results.xml'
        archiveArtifacts artifacts: 'coverage-report/**', fingerprint: true
    }
}
```

- Archived artifacts persist across builds and are downloadable from the Jenkins UI
- `fingerprint: true` lets Jenkins track which build produced which artifact

## What You'll Learn
- **Docker agents:** isolated, reproducible builds — no "works on my machine"
- **Per-stage agents:** different stages can use different Docker images
- **Jenkins Credentials Store:** secure secret management with types:
  - Username/password
  - Secret text
  - SSH key
  - Certificate
- **`withCredentials` binding:** injects secrets as env vars, masked in logs
- **Build artifacts:** files that persist beyond the build (reports, binaries, images)
- **Environment block:** define variables once, use everywhere

## Credential Types Reference

| Type | Use Case | Access Pattern |
|------|----------|---------------|
| Username/Password | Docker Hub, APIs with basic auth | `usernamePassword(credentialsId: ...)` |
| Secret Text | API tokens, single strings | `string(credentialsId: ...)` |
| SSH Key | Git clone via SSH, server access | `sshUserPrivateKey(credentialsId: ...)` |
| File | Kubeconfig, cert files | `file(credentialsId: ...)` |

## Files to Create/Modify
| File | Action | Purpose |
|------|--------|---------|
| `Jenkinsfile` | Update | Docker agent, credentials, artifacts |
| `app/Dockerfile` | Create | Docker image for the Flask app |
| `app/.coveragerc` | Create | Coverage configuration |

### app/Dockerfile
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

### app/.coveragerc
```ini
[run]
source = app
omit = tests/*

[report]
show_missing = true
```

### 3.7 Switch GitHub Repo to Private (Credential Practice)

In Step 1 the repo was public so Jenkins could clone without credentials. Now practice securing it:

1. On GitHub: **Settings → Danger Zone → Change visibility → Private**
2. Generate an SSH key pair (or use a PAT):
   ```bash
   ssh-keygen -t ed25519 -C "jenkins" -f ~/.ssh/jenkins_github
   ```
3. Add the **public key** to GitHub: **Settings → SSH and GPG keys → New SSH key**
4. Add the **private key** to Jenkins: **Manage Jenkins → Credentials → Add Credentials**
   - Kind: **SSH Username with private key**
   - ID: `github-ssh`
   - Username: `git`
   - Private Key: paste contents of `~/.ssh/jenkins_github`
5. In the job/pipeline config, update the Git URL to SSH format:
   ```
   git@github.com:yourusername/jenkins.git
   ```
   and select the `github-ssh` credential.

**Why this matters:** Real repos are private. This is the standard pattern for giving Jenkins access to any private Git host.

## Verification
- [ ] Build runs inside the Python Docker container (check console output for docker commands)
- [ ] Docker image is built and tagged with the build number
- [ ] Credentials are masked (`****`) in console output
- [ ] Coverage report is downloadable as an artifact from the build page
- [ ] If you remove the credential from Jenkins, the Push stage fails with an auth error
- [ ] GitHub repo is private; Jenkins still clones successfully using the SSH credential
- [ ] Removing the SSH credential from Jenkins causes the clone stage to fail with an auth error
