#!/bin/bash
# Fix docker socket permissions so Jenkins can use Docker
if [ -S /var/run/docker.sock ]; then
    chmod 666 /var/run/docker.sock
fi

# Drop back to jenkins user and run the original entrypoint
exec /usr/bin/tini -- /usr/local/bin/jenkins.sh "$@"
