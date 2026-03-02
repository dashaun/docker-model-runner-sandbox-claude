#!/usr/bin/env bash
# Runs before claude starts — bootstraps .claude.json so onboarding and
# login prompts are suppressed when using Docker Model Runner.
cat > /home/agent/.claude.json <<'EOF'
{"hasCompletedOnboarding":true,"installMethod":"native","primaryApiKey":"sk-ant-api03-dmr-placeholder-no-auth-required-for-local-model-runner"}
EOF
exec "$@"
