# Docker Model Runner Sandbox for Claude Code

A Docker sandbox template that runs [Claude Code](https://claude.ai/code) powered by local AI models via [Docker Model Runner](https://docs.docker.com/desktop/features/model-runner/). No cloud API keys required.

Docker Model Runner (Docker Desktop 4.40.0+) natively supports the Anthropic Messages API, so Claude Code connects directly with no translation layer.

## Prerequisites

- **Docker Desktop >= 4.40.0** with Model Runner enabled
  - Settings > Features in development > Enable Docker Model Runner
- A pulled model:
  ```bash
  docker model pull ai/qwen3-coder-next
  ```

## Quick Start

```bash
# One-time per machine — pulls the image and configures the sandbox proxy
docker run --rm -v ~/.sandboxd:/sandboxd dashaun/dmr-claude-sandbox setup-host
```

Then from any directory:

```bash
docker sandbox run -t dashaun/dmr-claude-sandbox claude . -- --dangerously-skip-permissions
```

### Changing the model

The model is baked into the image via `ANTHROPIC_MODEL`. To use a different model, build your own image:

```bash
git clone https://github.com/dashaun/docker-model-runner-sandbox-claude
# Edit ENV ANTHROPIC_MODEL in the Dockerfile
docker build -t my-claude-sandbox .
docker run --rm -v ~/.sandboxd:/sandboxd my-claude-sandbox setup-host
docker sandbox run -t my-claude-sandbox claude . -- --dangerously-skip-permissions
```

## How It Works

Docker sandboxes are network-isolated VMs. Reaching Docker Model Runner at `localhost:12434` requires two things:

1. **Proxy allowlist** — `setup-host` adds `localhost:12434` to `~/.sandboxd/proxy-config.json`, the global default policy inherited by all new sandboxes. This is a one-time, per-machine step.

2. **NO_PROXY wrapper** — Docker Desktop injects `NO_PROXY=localhost,...` into every exec'd process, which would bypass the proxy for localhost traffic. The image wraps the `claude` binary with a shell script that unsets `NO_PROXY` before launching, routing all traffic through the proxy.

## What's Included

- **Python tooling**: pytest, black, pylint, ruff, mypy
- **Java**: Bellsoft Liberica JDK 25 (via SDKMAN)
- **Utilities**: curl, jq, zip, unzip, build-essential

## Key Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ANTHROPIC_BASE_URL` | `http://localhost:12434` | Docker Model Runner endpoint (via sandbox proxy) |
| `ANTHROPIC_API_KEY` | `sk-ant-api03-dmr-placeholder-...` | Placeholder — DMR requires no auth, but Claude Code requires the `sk-ant-api03-` prefix |
| `ANTHROPIC_MODEL` | `docker.io/ai/qwen3-coder-next:latest` | Model to use |
| `DISABLE_PROMPT_CACHING` | `1` | Local models don't support prompt caching |

## Connectivity Check

From inside the sandbox, verify Docker Model Runner is reachable:

```bash
check-model-runner
```

## Troubleshooting

### "Unable to connect to API"

Re-run the setup command to ensure `localhost:12434` is in the proxy allowlist:

```bash
docker run --rm -v ~/.sandboxd:/sandboxd dashaun/dmr-claude-sandbox setup-host
```

Then recreate the sandbox so it picks up the updated policy:

```bash
docker sandbox rm dmr-claude-sandbox
docker sandbox run -t dashaun/dmr-claude-sandbox claude . -- --dangerously-skip-permissions
```

### Cannot connect to Docker Model Runner

1. Verify Docker Desktop >= 4.40.0
2. Enable Model Runner: Settings > Features in development > Enable Docker Model Runner
3. Pull a model: `docker model pull ai/qwen3-coder-next`
4. Verify it's running on the host: `curl http://localhost:12434/v1/models`

### Model not responding

- Check available models: `docker model list`
- Verify the model name matches `ANTHROPIC_MODEL` in the Dockerfile
- Restart Docker Desktop if Model Runner becomes unresponsive

### Java not found

SDKMAN initializes in interactive bash sessions. Inside the sandbox:

```bash
source /home/agent/.sdkman/bin/sdkman-init.sh
java -version
```
