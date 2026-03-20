# Step 1: Install Jenkins & Run Your First Freestyle Job

## Goal
Get Jenkins running and understand the UI, job creation, and build triggers.

## What You'll Do

### 1.1 Run Jenkins in Docker
```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
```

Or use the project's `docker-compose.yml`:
```bash
docker compose up -d
```

### 1.2 Initial Setup Wizard
- Navigate to `http://localhost:8080`
- Retrieve the unlock key: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
- Install **suggested plugins**
- Create an admin user

### 1.3 Create a Freestyle Project
1. **New Item** → name it `flask-api-build` → select **Freestyle project**
2. **Source Code Management** → Git → paste your repo URL
3. **Build Steps** → **Execute shell**:
   ```bash
   echo "Hello from Jenkins"
   python3 --version
   pip install -r requirements.txt
   pytest app/tests/
   ```
4. **Save** and click **Build Now**

### 1.4 Set Up Poll SCM Trigger
- Job config → **Build Triggers** → check **Poll SCM**
- Schedule: `H/5 * * * *` (every 5 minutes)
- This makes Jenkins check for new commits and build automatically

### 1.5 Read the Console Output
- Click on a build number → **Console Output**
- Understand what Jenkins did: workspace setup, git checkout, shell execution

## What You'll Learn
- **Jenkins architecture:** controller (manages jobs/UI), workspace (where code lives during a build), build executor (runs the job)
- **Freestyle jobs:** the simplest job type — configured entirely in the UI
- **Build triggers:** manual, poll SCM, and later webhooks
- **Console output:** your primary debugging tool in Jenkins
- **Plugin ecosystem:** Jenkins is plugin-driven; almost everything is a plugin

## Files to Create
| File | Purpose |
|------|---------|
| `app/app.py` | Minimal Flask app with 3 endpoints |
| `app/tests/test_app.py` | pytest tests for the endpoints |
| `app/requirements.txt` | Python dependencies (flask, pytest, flake8) |
| `docker-compose.yml` | Jenkins service definition |
| `Makefile` | Convenience commands: `make jenkins-up`, `make jenkins-logs` |

## Key Concepts Cheat Sheet

| Term | What It Means |
|------|--------------|
| **Controller** | The Jenkins server — runs the UI, schedules jobs |
| **Agent/Node** | A machine that executes builds (controller can also be an agent) |
| **Workspace** | Directory on the agent where the repo is checked out |
| **Build** | A single execution of a job |
| **Freestyle project** | Job type configured entirely via UI — no code |
| **Poll SCM** | Jenkins periodically checks the repo for changes |

## Verification
- [ ] Jenkins UI accessible at localhost:8080
- [ ] Freestyle job runs and shows green (SUCCESS)
- [ ] Console output shows your echo and pytest results
- [ ] Break a test intentionally → job goes red (FAILURE)
- [ ] Poll SCM triggers a build after you push a commit

## What to Do Next

Move to **[Step 2: Declarative Pipeline as Code](step2-pipeline-as-code.md)**.

The Freestyle job you just built has a fundamental problem: the build configuration lives entirely in the Jenkins UI. If Jenkins dies, you lose it. If a teammate clones the repo, they have no idea how to build it. There's no review process for changing the build steps.

Step 2 fixes this by moving the pipeline definition into a `Jenkinsfile` committed alongside your code — so the build is versioned, reviewable, and portable.

**Before moving on, make sure you can answer these:**
- Where does Jenkins store the workspace for your job? (Hint: check the console output for the path)
- What's the difference between a build **executor** and a build **agent**?
- Why does Poll SCM use `H/5` instead of `*/5`? (Hint: look up "hash trigger" in Jenkins docs)
