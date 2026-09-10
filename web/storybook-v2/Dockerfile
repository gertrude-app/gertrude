FROM mcr.microsoft.com/playwright:v1.61.1-noble@sha256:824f1a789072e648c62541c2cfa4479c4061a290d5c27766d67dc1dcbc19b321

ENV CI=true \
    TZ=UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    CYPRESS_INSTALL_BINARY=0 \
    PUPPETEER_SKIP_DOWNLOAD=true \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    STORYBOOK_DISABLE_TELEMETRY=1

WORKDIR /workspace
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN npm install --global "$(node -p 'require("./package.json").packageManager')" \
    && pnpm fetch --frozen-lockfile

COPY . .
RUN pnpm --filter storybook-v2... --filter account... install --offline --frozen-lockfile \
    && pnpm --filter storybook-v2 build

WORKDIR /workspace/storybook-v2
RUN node --test scripts/__tests__/wait-for-story.browser.js
CMD ["node", "scripts/screenshot-stories.js"]
