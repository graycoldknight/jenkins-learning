#!/bin/bash
set -e
TARGET=${1:-staging}
IMAGE="${REGISTRY}/${APP_NAME}:${APP_VERSION}"

if [ "$TARGET" = "production" ]; then
    PORT=5000
else
    PORT=5001
fi

CONTAINER="flask-api-${TARGET}"

echo "Deploying ${IMAGE} to ${TARGET} on port ${PORT}..."

# Stop existing container if running
docker rm -f "${CONTAINER}" 2>/dev/null || true

docker run -d \
    --name "${CONTAINER}" \
    -p "${PORT}:5000" \
    -e "FLASK_ENV=${TARGET}" \
    --restart unless-stopped \
    "${IMAGE}"

echo "Deployment to ${TARGET} complete."
