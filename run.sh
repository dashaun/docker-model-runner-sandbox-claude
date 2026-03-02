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

# Configure the filtering proxy to allow requests to localhost:12434 (Docker Model Runner).
# Docker Desktop's sandbox proxy blocks all private IPs by default; adding localhost to
# allowedDomains lets it forward to DMR on the host.
# Requires a RUNNING sandbox VM — 'docker sandbox network proxy' talks to the live VM.
configure_proxy() {
    local name="$1"
    local proxy_cfg=~/.docker/sandboxes/vm/"${name}"/proxy-config.json
    if [[ -f "${proxy_cfg}" ]]; then
        if ! python3 -c "
import json, sys
d = json.load(open('${proxy_cfg}'))
sys.exit(0 if 'localhost' in d.get('network', {}).get('allowedDomains', []) else 1)
" 2>/dev/null; then
            echo "Configuring sandbox proxy for Docker Model Runner access..."
            docker sandbox network proxy "${name}" --allow-host localhost
        fi
    fi
}

# Returns 0 if the sandbox proxy already has localhost in allowedDomains
proxy_has_localhost() {
    local name="$1"
    local proxy_cfg=~/.docker/sandboxes/vm/"${name}"/proxy-config.json
    [[ -f "${proxy_cfg}" ]] && python3 -c "
import json, sys
d = json.load(open('${proxy_cfg}'))
sys.exit(0 if 'localhost' in d.get('network', {}).get('allowedDomains', []) else 1)
" 2>/dev/null
}

EXISTING_SANDBOX=$(docker sandbox ls 2>/dev/null | awk -v ws="$(pwd)" '$NF == ws {print $1}')

# If an existing sandbox lacks proxy config, remove and recreate it so the full
# setup sequence (create → proxy → stop → run) runs cleanly.
if [[ -n "${EXISTING_SANDBOX}" ]] && ! proxy_has_localhost "${EXISTING_SANDBOX}"; then
    echo "Existing sandbox '${EXISTING_SANDBOX}' lacks proxy config. Recreating..."
    docker sandbox rm "${EXISTING_SANDBOX}"
    EXISTING_SANDBOX=""
fi

if [[ -n "${EXISTING_SANDBOX}" ]]; then
    echo "Resuming existing sandbox '${EXISTING_SANDBOX}'..."
    docker sandbox stop "${EXISTING_SANDBOX}" 2>/dev/null || true
    docker sandbox run "${EXISTING_SANDBOX}" -- --dangerously-skip-permissions
else
    echo "Creating new sandbox '${SANDBOX_NAME}'..."
    docker sandbox create \
        -t "${IMAGE_NAME}" \
        --name "${SANDBOX_NAME}" \
        claude .
    # Configure proxy while VM is running (just started by docker sandbox create)
    configure_proxy "${SANDBOX_NAME}"
    # Stop so docker sandbox run starts the container fresh (reads proxy-config.json)
    docker sandbox stop "${SANDBOX_NAME}" 2>/dev/null || true
    docker sandbox run "${SANDBOX_NAME}" -- --dangerously-skip-permissions
fi
