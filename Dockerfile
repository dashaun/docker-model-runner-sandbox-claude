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
COPY scripts/verify-env.sh /usr/local/bin/verify-env
COPY scripts/entrypoint.sh /usr/local/bin/sandbox-entrypoint
RUN chmod +x /usr/local/bin/check-model-runner /usr/local/bin/verify-env /usr/local/bin/sandbox-entrypoint

# Docker Model Runner environment defaults
ENV ANTHROPIC_BASE_URL=http://model-runner.docker.internal
ENV ANTHROPIC_API_KEY=sk-ant-api03-dmr-placeholder-no-auth-required-for-local-model-runner
ENV ANTHROPIC_MODEL=ai/qwen3-coder-next
ENV DISABLE_PROMPT_CACHING=1
ENV IS_DEMO=1

ENTRYPOINT ["/usr/local/bin/sandbox-entrypoint"]

USER agent

# Install SDKMAN and Bellsoft Liberica Java 25
RUN curl -s "https://get.sdkman.io" | bash \
    && bash -c "source /home/agent/.sdkman/bin/sdkman-init.sh"

# Configure SDKMAN in agent's bashrc
RUN echo '' >> /home/agent/.bashrc \
    && echo '# SDKMAN' >> /home/agent/.bashrc \
    && echo 'export SDKMAN_DIR="/home/agent/.sdkman"' >> /home/agent/.bashrc \
    && echo '[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"' >> /home/agent/.bashrc \
    && echo '' >> /home/agent/.bashrc \
    && echo '# Docker Model Runner environment' >> /home/agent/.bashrc \
    && echo 'export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-http://model-runner.docker.internal}"' >> /home/agent/.bashrc \
    && echo 'export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-sk-ant-api03-dmr-placeholder-no-auth-required-for-local-model-runner}"' >> /home/agent/.bashrc \
    && echo 'export ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-ai/qwen3-coder-next}"' >> /home/agent/.bashrc \
    && echo 'export DISABLE_PROMPT_CACHING="${DISABLE_PROMPT_CACHING:-1}"' >> /home/agent/.bashrc

# Persist SDKMAN for Claude Code environment (no bash_completion — it breaks the bash tool)
RUN echo 'export SDKMAN_DIR="/home/agent/.sdkman"' >> /etc/sandbox-persistent.sh \
    && echo '[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"' >> /etc/sandbox-persistent.sh

# Persist Docker Model Runner environment variables for Claude Code
RUN echo '' >> /etc/sandbox-persistent.sh \
    && echo '# Docker Model Runner environment' >> /etc/sandbox-persistent.sh \
    && echo 'export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-http://model-runner.docker.internal}"' >> /etc/sandbox-persistent.sh \
    && echo 'export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-sk-ant-api03-dmr-placeholder-no-auth-required-for-local-model-runner}"' >> /etc/sandbox-persistent.sh \
    && echo 'export ANTHROPIC_MODEL="${ANTHROPIC_MODEL:-ai/qwen3-coder-next}"' >> /etc/sandbox-persistent.sh \
    && echo 'export DISABLE_PROMPT_CACHING="${DISABLE_PROMPT_CACHING:-1}"' >> /etc/sandbox-persistent.sh \
    && echo 'export IS_DEMO="${IS_DEMO:-1}"' >> /etc/sandbox-persistent.sh

# Merge onboarding/auth bypass fields into .claude.json — must be last to win over base image writes
RUN jq '. + {"hasCompletedOnboarding": true, "primaryApiKey": "sk-ant-api03-dmr-placeholder-no-auth-required-for-local-model-runner"}' \
    /home/agent/.claude.json > /tmp/claude.json \
    && mv /tmp/claude.json /home/agent/.claude.json
