# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This is a hands-on Jenkins learning project. The Flask app (`app/`) is purely a vehicle for Jenkins pipelines — it exists to be built, linted, tested, and deployed through Jenkins. The real work happens in `Jenkinsfile`s, shared libraries, and Jenkins configuration, not in the app logic itself.

The learning path is documented step-by-step in `.plan/` — read `overview.md` first, then the numbered step files.

## Commands

```bash
# Jenkins lifecycle
make jenkins-up       # Start Jenkins (docker compose up -d)
make jenkins-down     # Stop Jenkins
make jenkins-logs     # Tail Jenkins logs
make jenkins-unlock   # Print initial admin password for setup wizard

# App development (run from repo root)
make test             # pytest app/tests/ -v
make lint             # flake8 app/
```

Run a single test (must `cd app` because tests import `from app import app`):
```bash
cd app && pytest tests/test_app.py::test_health -v
```

## Architecture

The pipeline flow: Git push → Jenkins detects change → Lint → Test (Python Docker agent) → Build Docker image → Push to Docker Hub → Deploy (staging or production).

Key architectural decisions:
- **`agent none` at top level** with per-stage agents. Lint/Test stages nest inside a single `docker { image 'python:3.11-slim' }` agent. Build/Push/Deploy stages use `agent any` (the Jenkins controller, which has docker.sock access).
- **`stash`/`unstash`** passes workspace contents between agents since each agent gets a fresh workspace.
- **docker.sock mount** (`docker-compose.yml`) lets Jenkins run `docker build`/`docker push` against the host daemon. `Dockerfile.jenkins` + `entrypoint.sh` fix socket permissions at container startup.
- **Conditional deployment:** `when { branch 'develop' }` deploys to staging automatically; `when { branch 'main' }` requires manual `input` approval before production deploy.
- **Staging** runs on port 5001, **production** on port 5000 (see `docker-compose.staging.yml` / `docker-compose.prod.yml`).

## Jenkins UI

Jenkins runs at `http://localhost:8080`. Port 50000 is the JNLP agent port (used when adding separate build agents).

The `jenkins_home` Docker volume persists all Jenkins configuration, jobs, credentials, and build history across container restarts.

## Credentials

Docker Hub credentials are stored in Jenkins as `dockerhub-creds` (username/password type), referenced in the Jenkinsfile via `withCredentials`.
