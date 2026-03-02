#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="dmr-claude-sandbox"
SANDBOX_NAME="${SANDBOX_NAME:-dmr-claude-sandbox}"

# Build image if it doesn't exist
if ! docker image inspect "${IMAGE_NAME}" &>/dev/null; then
    echo "Image '${IMAGE_NAME}' not found. Building..."
    docker build -t "${IMAGE_NAME}" .
fi

echo "Starting Claude Code sandbox with Docker Model Runner..."
echo "  Sandbox: ${SANDBOX_NAME}"
echo "  Image:   ${IMAGE_NAME}"
echo ""

# Detect existing sandbox for this workspace by path, then resume or create
EXISTING_SANDBOX=$(docker sandbox ls 2>/dev/null | awk -v ws="$(pwd)" '$NF == ws {print $1}')

if [[ -n "${EXISTING_SANDBOX}" ]]; then
    echo "Resuming existing sandbox '${EXISTING_SANDBOX}'..."
    docker sandbox run "${EXISTING_SANDBOX}" -- --dangerously-skip-permissions
else
    echo "Creating new sandbox '${SANDBOX_NAME}'..."
    docker sandbox run \
        -t "${IMAGE_NAME}" \
        --name "${SANDBOX_NAME}" \
        claude . \
        -- --dangerously-skip-permissions
fi
