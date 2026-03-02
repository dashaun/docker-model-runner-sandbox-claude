#!/usr/bin/env bash
# Verify Docker Model Runner environment variables are set

echo "=== Docker Model Runner Environment Variables ==="
echo "ANTHROPIC_BASE_URL: ${ANTHROPIC_BASE_URL:-[NOT SET]}"
echo "ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-[NOT SET]}"
echo "ANTHROPIC_MODEL: ${ANTHROPIC_MODEL:-[NOT SET]}"
echo "DISABLE_PROMPT_CACHING: ${DISABLE_PROMPT_CACHING:-[NOT SET]}"
echo ""

if [[ -z "${ANTHROPIC_BASE_URL}" ]] || [[ -z "${ANTHROPIC_API_KEY}" ]]; then
    echo "ERROR: Required environment variables are not set!"
    echo "Claude Code will prompt for credentials."
    exit 1
else
    echo "SUCCESS: Environment variables are properly configured."
    exit 0
fi
