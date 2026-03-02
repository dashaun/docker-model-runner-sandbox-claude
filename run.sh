#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="dmr-claude-sandbox"
SANDBOX_NAME="${SANDBOX_NAME:-dmr-claude-sandbox}"

if ! docker image inspect "${IMAGE_NAME}" &>/dev/null; then
    echo "Image '${IMAGE_NAME}' not found. Building..."
    docker build -t "${IMAGE_NAME}" .
fi

EXISTING=$(docker sandbox ls 2>/dev/null | awk -v ws="$(pwd)" '$NF == ws {print $1}')

if [[ -z "${EXISTING}" ]]; then
    # First-time setup: create sandbox, configure proxy, then run.
    # The proxy allowlist (--allow-host localhost) lets the sandbox proxy forward
    # requests to Docker Model Runner at localhost:12434 on the host. It must be
    # set while the VM is running (docker sandbox create starts the VM) and before
    # the agent starts (docker sandbox run starts the agent).
    docker sandbox create -t "${IMAGE_NAME}" --name "${SANDBOX_NAME}" claude .
    docker sandbox network proxy "${SANDBOX_NAME}" --allow-host localhost
    EXISTING="${SANDBOX_NAME}"
fi

docker sandbox run "${EXISTING}" -- --dangerously-skip-permissions
