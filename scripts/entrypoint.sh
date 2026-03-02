#!/usr/bin/env bash
# Runs as PID1 before the claude agent is exec'd into the container.
#
# Clear NO_PROXY so any process started directly from this shell (e.g. bash
# tool subprocesses) routes localhost traffic through the sandbox proxy.
# The claude binary itself is handled by the claude wrapper in the image.
export NO_PROXY=""
export no_proxy=""

# Bootstrap .claude.json to suppress onboarding and login prompts.
cat > /home/agent/.claude.json <<'EOF'
{"hasCompletedOnboarding":true,"installMethod":"native","primaryApiKey":"sk-ant-api03-dmr-placeholder-no-auth-required-for-local-model-runner"}
EOF

exec "$@"
