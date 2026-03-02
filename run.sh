#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="dmr-claude-sandbox"

# Build image if it doesn't exist
if ! docker image inspect "${IMAGE_NAME}" &>/dev/null; then
    echo "Image '${IMAGE_NAME}' not found. Building..."
    docker build -t "${IMAGE_NAME}" .
fi

# Ensure the global sandbox proxy allows localhost:12434 (Docker Model Runner endpoint).
# ~/.sandboxd/proxy-config.json is the default policy inherited by ALL new sandboxes —
# adding localhost:12434 here means no per-sandbox proxy configuration is ever needed.
GLOBAL_PROXY="${HOME}/.sandboxd/proxy-config.json"
if [[ -f "${GLOBAL_PROXY}" ]] && ! python3 -c "
import json, sys
d = json.load(open('${GLOBAL_PROXY}'))
sys.exit(0 if 'localhost:12434' in d.get('network', {}).get('allowedDomains', []) else 1)
" 2>/dev/null; then
    echo "Adding localhost:12434 to global sandbox proxy allowlist..."
    python3 -c "
import json
with open('${GLOBAL_PROXY}') as f:
    d = json.load(f)
d.setdefault('network', {}).setdefault('allowedDomains', []).append('localhost:12434')
with open('${GLOBAL_PROXY}', 'w') as f:
    json.dump(d, f, indent=2)
"
fi

docker sandbox run -t "${IMAGE_NAME}" claude . -- --dangerously-skip-permissions
