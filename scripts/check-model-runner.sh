#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${ANTHROPIC_BASE_URL:-http://model-runner.docker.internal}"

echo "Checking Docker Model Runner connectivity..."
echo "URL: ${BASE_URL}/v1/models"
echo ""

if ! command -v curl &>/dev/null; then
    echo "ERROR: curl is not installed."
    exit 1
fi

HTTP_CODE=$(curl -s -o /tmp/dmr-response.json -w "%{http_code}" "${BASE_URL}/v1/models" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "000" ]; then
    echo "FAILED: Cannot connect to Docker Model Runner at ${BASE_URL}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Ensure Docker Desktop >= 4.58.0 is installed"
    echo "  2. Enable Model Runner: Docker Desktop > Settings > Features in development > Model Runner"
    echo "  3. Pull a model: docker model pull ai/qwen3-coder-next"
    echo "  4. Verify the container can reach model-runner.docker.internal"
    exit 1
elif [ "$HTTP_CODE" != "200" ]; then
    echo "FAILED: Received HTTP ${HTTP_CODE} from Docker Model Runner"
    echo "Response:"
    cat /tmp/dmr-response.json 2>/dev/null
    exit 1
else
    echo "SUCCESS: Docker Model Runner is reachable."
    echo ""
    echo "Available models:"
    if command -v jq &>/dev/null; then
        jq -r '.data[]?.id // empty' /tmp/dmr-response.json 2>/dev/null || cat /tmp/dmr-response.json
    else
        cat /tmp/dmr-response.json
    fi
fi

rm -f /tmp/dmr-response.json
