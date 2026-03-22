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

```
jenkins/
  app/                  # Flask API (the thing Jenkins builds/tests/deploys)
    app.py              # Three endpoints: /health, /greet/<name>, /add/<a>/<b>
    tests/              # pytest tests using Flask test_client fixture
    requirements.txt    # Pinned deps: flask, pytest, flake8, pytest-cov
  docker-compose.yml    # Runs Jenkins LTS; mounts docker.sock for Docker-in-Docker
  Makefile              # Shortcuts for Jenkins and app commands
  .plan/                # Step-by-step learning plan (overview.md + 5 step files)
```

**docker.sock mount:** `docker-compose.yml` mounts `/var/run/docker.sock` into the Jenkins container so that pipeline stages can run `docker build`/`docker push` against the host daemon. This is required for Steps 3–5.

**Steps 3–5 add files not yet present:** `Dockerfile`, `.flake8`, `Jenkinsfile`, `deploy.sh`, and `jenkins-shared-library/` will be created as each step is executed.

## Jenkins UI

Jenkins runs at `http://localhost:8080`. Port 50000 is the JNLP agent port (used when adding separate build agents).

The `jenkins_home` Docker volume persists all Jenkins configuration, jobs, credentials, and build history across container restarts.
