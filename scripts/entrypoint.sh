#!/usr/bin/env bash

if [[ "${1:-}" == "setup-host" ]]; then
    # Host setup mode: add localhost:12434 to the global sandbox proxy allowlist.
    # Usage: docker run --rm -v ~/.sandboxd:/sandboxd dashaun/dmr-claude-sandbox setup-host
    PROXY_CONFIG="/sandboxd/proxy-config.json"
    if [[ ! -f "$PROXY_CONFIG" ]]; then
        echo "ERROR: $PROXY_CONFIG not found."
        echo "Mount ~/.sandboxd into the container: docker run --rm -v ~/.sandboxd:/sandboxd ..."
        exit 1
    fi
    python3 -c "
import json, sys
with open('$PROXY_CONFIG') as f:
    d = json.load(f)
domains = d.setdefault('network', {}).setdefault('allowedDomains', [])
if 'localhost:12434' in domains:
    print('localhost:12434 already in proxy allowlist — nothing to do.')
    sys.exit(0)
domains.append('localhost:12434')
with open('$PROXY_CONFIG', 'w') as f:
    json.dump(d, f, indent=2)
print('Added localhost:12434 to proxy allowlist.')
"
    exit $?
fi

# Normal sandbox mode: clear NO_PROXY and bootstrap .claude.json before exec-ing the agent.
export NO_PROXY=""
export no_proxy=""

cat > /home/agent/.claude.json <<'EOF'
{"hasCompletedOnboarding":true,"installMethod":"native","primaryApiKey":"sk-ant-api03-dmr-placeholder-no-auth-required-for-local-model-runner"}
EOF

exec "$@"
