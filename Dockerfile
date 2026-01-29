FROM node:22-bookworm-slim

LABEL org.opencontainers.image.source="https://github.com/phioranex/moltbot-docker"
LABEL org.opencontainers.image.description="Pre-built Moltbot Docker image"
LABEL org.opencontainers.image.licenses="MIT"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bun (required for build)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

# Enable corepack for pnpm
RUN corepack enable

WORKDIR /app

# Clone and build Moltbot
ARG MOLTBOT_VERSION=main
RUN git clone --depth 1 --branch ${MOLTBOT_VERSION} https://github.com/moltbot/moltbot.git .

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build
RUN pnpm build
RUN pnpm ui:install
RUN pnpm ui:build

# Clean up build artifacts to reduce image size
RUN rm -rf .git node_modules/.cache

# Create app user (node already exists in base image)
RUN mkdir -p /home/node/.clawdbot /home/node/clawd \
    && chown -R node:node /home/node /app

USER node

WORKDIR /home/node

ENV NODE_ENV=production
ENV PATH="/app/node_modules/.bin:${PATH}"

# Default command
ENTRYPOINT ["node", "/app/dist/index.js"]
CMD ["--help"]
