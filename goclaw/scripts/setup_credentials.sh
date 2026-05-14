#!/bin/sh
# Setup credentials after container recreate
# Run AFTER setup_all_tools.sh
# Usage: docker exec -u root goclaw-goclaw-1 sh /app/workspace/setup_credentials.sh

echo "Setting up Claude CLI credentials..."
mkdir -p /app/.claude
cp /app/workspace/.claude-credentials.json /app/.claude/.credentials.json
chown goclaw:goclaw /app/.claude/.credentials.json
chmod 600 /app/.claude/.credentials.json

echo "Verifying..."
docker_exec_as_goclaw() { su -s /bin/sh goclaw -c "$1"; }
claude auth status 2>/dev/null | grep loggedIn || echo "Run as goclaw user to verify"

echo "Done. Test with: docker exec -u goclaw goclaw-goclaw-1 claude auth status"
