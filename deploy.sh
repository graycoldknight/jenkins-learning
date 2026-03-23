#!/bin/bash
set -e
TARGET=${1:-staging}
echo "Deploying to ${TARGET}..."
docker compose -f "docker-compose.${TARGET}.yml" up -d
echo "Deployment to ${TARGET} complete."
