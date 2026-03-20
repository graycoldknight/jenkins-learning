# Jenkins Learning Project: CI/CD Pipeline for a Dockerized Flask API

A single project that grows in complexity across 5 steps, teaching Jenkins from installation through advanced pipeline features.

**Project concept:** A Python Flask API with tests, linting, Docker packaging, and multi-environment deployment — all automated through Jenkins.

## Progression

| Step | File | Concept | Key Jenkins Feature |
|------|------|---------|-------------------|
| 1 | [step1-install-and-first-job.md](step1-install-and-first-job.md) | Installation & first job | Freestyle project, poll SCM |
| 2 | [step2-pipeline-as-code.md](step2-pipeline-as-code.md) | Pipeline as code | Declarative Jenkinsfile, JUnit |
| 3 | [step3-docker-credentials-artifacts.md](step3-docker-credentials-artifacts.md) | Containers & secrets | Docker agent, credentials, artifacts |
| 4 | [step4-multibranch-webhooks-notifications.md](step4-multibranch-webhooks-notifications.md) | Multi-branch & CD gates | Multibranch pipeline, webhooks, `when`/`input` |
| 5 | [step5-shared-libraries-parallel.md](step5-shared-libraries-parallel.md) | Reuse & parallelism | Shared libraries, parallel stages, Blue Ocean |

## Verification Approach
After each step:
1. Push a commit and confirm the build triggers
2. Intentionally break something (test, lint, deploy) to see failure handling
3. Check that artifacts/reports/notifications appear correctly
