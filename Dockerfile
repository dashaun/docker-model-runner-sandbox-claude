FROM docker/sandbox-templates:claude-code

USER root

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-pip \
    python3-venv \
    curl \
    jq \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Python development tools
RUN pip3 install --no-cache-dir --break-system-packages \
    pytest \
    black \
    pylint \
    ruff \
    mypy

# Copy utility scripts
COPY scripts/check-model-runner.sh /usr/local/bin/check-model-runner
COPY scripts/entrypoint.sh /usr/local/bin/sandbox-entrypoint
RUN chmod +x /usr/local/bin/check-model-runner /usr/local/bin/sandbox-entrypoint

# Docker Model Runner environment defaults
ENV ANTHROPIC_BASE_URL=http://localhost:12434
ENV ANTHROPIC_API_KEY=sk-ant-api03-dmr-placeholder-no-auth-required-for-local-model-runner
ENV ANTHROPIC_MODEL=docker.io/ai/qwen3-coder-next:latest
ENV DISABLE_PROMPT_CACHING=1
ENV IS_DEMO=1

ENTRYPOINT ["/usr/local/bin/sandbox-entrypoint"]

USER agent

# Install SDKMAN and Bellsoft Liberica Java 25
RUN curl -s "https://get.sdkman.io" | bash \
    && bash -c "source /home/agent/.sdkman/bin/sdkman-init.sh"

# Configure SDKMAN in agent's bashrc (for interactive sessions)
RUN echo '' >> /home/agent/.bashrc \
    && echo '# SDKMAN' >> /home/agent/.bashrc \
    && echo 'export SDKMAN_DIR="/home/agent/.sdkman"' >> /home/agent/.bashrc \
    && echo '[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"' >> /home/agent/.bashrc

# Configure sandbox-persistent.sh (sourced by Claude Code's bash tool subprocesses via BASH_ENV).
# ANTHROPIC_* vars are already ENV-inherited; only NO_PROXY needs explicit clearing here since
# docker exec injects NO_PROXY=localhost,... but bash subprocesses inherit from the claude wrapper
# which already unsets it — this is belt-and-suspenders for any bash started outside that chain.
RUN echo 'export SDKMAN_DIR="/home/agent/.sdkman"' >> /etc/sandbox-persistent.sh \
    && echo '[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"' >> /etc/sandbox-persistent.sh \
    && echo 'export NO_PROXY=""' >> /etc/sandbox-persistent.sh \
    && echo 'export no_proxy=""' >> /etc/sandbox-persistent.sh

# Wrap the claude binary to clear NO_PROXY before startup.
# Docker Desktop always injects NO_PROXY=localhost,127.0.0.1,::1 into every exec'd
# process — including the claude agent — which causes localhost:12434 requests to
# bypass the sandbox proxy and hit the empty sandbox loopback instead of reaching
# Docker Model Runner. The wrapper unsets NO_PROXY/no_proxy before exec-ing the
# real binary, so the proxy receives and forwards the request to DMR on the host.
RUN mv /home/agent/.local/bin/claude /home/agent/.local/bin/claude.real \
    && printf '#!/bin/sh\nunset NO_PROXY no_proxy\nexec /home/agent/.local/bin/claude.real "$@"\n' \
       > /home/agent/.local/bin/claude \
    && chmod +x /home/agent/.local/bin/claude
