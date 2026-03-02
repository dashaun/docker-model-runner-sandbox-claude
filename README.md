# Docker Model Runner Sandbox for Claude Code

A Docker sandbox environment that runs [Claude Code](https://claude.ai/code) powered by local AI models via [Docker Model Runner](https://docs.docker.com/desktop/features/model-runner/). No cloud API keys required.

Docker Model Runner (Docker Desktop 4.58.0+) natively supports the Anthropic Messages API at `/v1/messages`, so Claude Code connects directly with no translation layer.

## Prerequisites

- **Docker Desktop >= 4.58.0** with Model Runner enabled
  - Settings > Features in development > Model Runner
- A pulled model (e.g., `ai/qwen3-coder-next`)

## Quick Start

```bash
# 1. Pull the model
docker model pull ai/qwen3-coder-next

# 2. Build the sandbox image
docker build -t dmr-claude-sandbox .

# 3. Launch
./run.sh
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ANTHROPIC_BASE_URL` | `http://model-runner.docker.internal` | Docker Model Runner endpoint |
| `ANTHROPIC_API_KEY` | `sk-ant-api03-dmr-placeholder-...` | Formatted placeholder — DMR accepts any value, but Claude Code requires the `sk-ant-api03-` prefix to bypass the login prompt |
| `ANTHROPIC_MODEL` | `ai/qwen3-coder-next` | Model to use |
| `DISABLE_PROMPT_CACHING` | `1` | Local models don't support prompt caching |

Override at launch:

```bash
MODEL=ai/some-other-model ./run.sh
```

## Manual `docker run`

```bash
docker run -it --rm \
    -e ANTHROPIC_BASE_URL=http://model-runner.docker.internal \
    -e ANTHROPIC_API_KEY=sk-ant-api03-dmr-placeholder-no-auth-required-for-local-model-runner \
    -e ANTHROPIC_MODEL=ai/qwen3-coder-next \
    -e DISABLE_PROMPT_CACHING=1 \
    dmr-claude-sandbox \
    claude --model ai/qwen3-coder-next
```

## Connectivity Check

From inside the container, verify Docker Model Runner is reachable:

```bash
check-model-runner
```

This checks `${ANTHROPIC_BASE_URL}/v1/models` and lists available models.

## What's Included

The sandbox image includes:

- **Python tooling**: pytest, black, pylint, ruff, mypy
- **Java**: Bellsoft Liberica JDK 25 (via SDKMAN)
- **Utilities**: curl, jq, zip, unzip, build-essential

## Troubleshooting

### Cannot connect to Docker Model Runner

1. Verify Docker Desktop version >= 4.58.0
2. Enable Model Runner: Settings > Features in development > Model Runner
3. Pull a model: `docker model pull ai/qwen3-coder-next`
4. Run `check-model-runner` inside the container to diagnose

### Model not responding

- Check available models: `docker model list`
- Ensure the model name matches what's pulled (e.g., `ai/qwen3-coder-next`)
- Restart Docker Desktop if Model Runner becomes unresponsive

### Java not found

Inside the container, use a login shell:

```bash
bash -l -c "java -version"
```

Or source SDKMAN directly:

```bash
source /home/agent/.sdkman/bin/sdkman-init.sh
java -version
```
