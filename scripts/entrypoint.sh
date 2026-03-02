#!/usr/bin/env bash
# Runs before claude starts.
#
# The sandbox proxy injects NO_PROXY=localhost,127.0.0.1,::1, which causes
# HTTP clients to connect to localhost DIRECTLY (hitting the empty sandbox
# loopback) instead of going through the proxy. Clearing NO_PROXY forces
# localhost:12434 traffic through the proxy, which has been configured to
# allow localhost (docker sandbox network proxy --allow-host localhost).
export NO_PROXY=""
export no_proxy=""

# Use the proxy-accessible DMR endpoint
export ANTHROPIC_BASE_URL="http://localhost:12434"

# Bootstrap .claude.json to suppress onboarding and login prompts
cat > /home/agent/.claude.json <<'EOF'
{"hasCompletedOnboarding":true,"installMethod":"native","primaryApiKey":"sk-ant-api03-dmr-placeholder-no-auth-required-for-local-model-runner"}
EOF

exec "$@"
