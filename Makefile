.PHONY: jenkins-up jenkins-down jenkins-logs jenkins-unlock test lint

jenkins-up:
	docker compose up -d

jenkins-down:
	docker compose down

jenkins-logs:
	docker compose logs -f jenkins

jenkins-unlock:
	docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

test:
	cd app && pytest tests/ -v

lint:
	cd app && flake8 .
