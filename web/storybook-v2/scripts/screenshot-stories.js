import { createReadStream } from 'node:fs';
import { mkdir, readFile, rm, stat, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';
import { cpus } from 'node:os';
import { dirname, extname, join, normalize, relative, resolve, sep } from 'node:path';
import { chromium } from 'playwright';

const storybookDir = resolve(process.env.STORYBOOK_DIR ?? `storybook-static`);
const outputDir = resolve(process.env.SCREENSHOT_DIR ?? `screenshots`);
const host = process.env.STORYBOOK_HOST ?? `127.0.0.1`;
const port = Number(process.env.STORYBOOK_PORT ?? 0);
const defaultConcurrency = Math.min(Math.max(cpus().length - 1, 1), 4);

const mimeTypes = new Map([
  [`.css`, `text/css; charset=utf-8`],
  [`.gif`, `image/gif`],
  [`.html`, `text/html; charset=utf-8`],
  [`.ico`, `image/x-icon`],
  [`.jpg`, `image/jpeg`],
  [`.js`, `text/javascript; charset=utf-8`],
  [`.json`, `application/json; charset=utf-8`],
  [`.map`, `application/json; charset=utf-8`],
  [`.png`, `image/png`],
  [`.svg`, `image/svg+xml; charset=utf-8`],
  [`.webp`, `image/webp`],
  [`.woff`, `font/woff`],
  [`.woff2`, `font/woff2`],
]);

const disableAnimationsCss = `
  *, *::before, *::after {
    animation-delay: 0s !important;
    animation-duration: 0s !important;
    caret-color: transparent !important;
    transition-delay: 0s !important;
    transition-duration: 0s !important;
  }
`;

function writeStdout(message) {
  process.stdout.write(`${message}\n`);
}

function positiveInteger(value, fallback) {
  const parsed = Number.parseInt(value ?? ``, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

const concurrency = positiveInteger(
  process.env.SCREENSHOT_CONCURRENCY,
  defaultConcurrency,
);

function safeJoin(root, urlPathname) {
  const relativePath = normalize(decodeURIComponent(urlPathname)).replace(/^[/\\]+/, ``);
  const filePath = join(root, relativePath || `index.html`);
  return filePath === root || filePath.startsWith(`${root}${sep}`) ? filePath : undefined;
}

async function fileExists(filePath) {
  try {
    return (await stat(filePath)).isFile();
  } catch {
    return false;
  }
}

function serveStatic(root) {
  const server = createServer(async (request, response) => {
    try {
      const requestUrl = new URL(request.url ?? `/`, `http://${host}`);
      const filePath = safeJoin(root, requestUrl.pathname);

      if (!filePath) {
        response.writeHead(403);
        response.end(`Forbidden`);
        return;
      }

      if (!(await fileExists(filePath))) {
        response.writeHead(404);
        response.end(`Not found`);
        return;
      }

      response.writeHead(200, {
        [`Content-Type`]: mimeTypes.get(extname(filePath)) ?? `application/octet-stream`,
      });
      createReadStream(filePath).pipe(response);
    } catch (error) {
      response.writeHead(500);
      response.end(error instanceof Error ? error.message : `Internal server error`);
    }
  });

  return new Promise((resolveServer, reject) => {
    server.once(`error`, reject);
    server.listen(port, host, () => {
      server.off(`error`, reject);
      resolveServer(server);
    });
  });
}

async function readStories() {
  const indexPath = join(storybookDir, `index.json`);
  let storyIndex;

  try {
    storyIndex = JSON.parse(await readFile(indexPath, `utf8`));
  } catch (error) {
    throw new Error(
      `Could not read ${indexPath}. Run \`pnpm --filter storybook-v2 build\` first, or use \`pnpm --filter storybook-v2 visual:update\`.`,
      { cause: error },
    );
  }

  const stories = Object.values(storyIndex.entries ?? {})
    .filter((entry) => entry?.type === `story`)
    .sort((a, b) => a.id.localeCompare(b.id));

  if (stories.length === 0) {
    throw new Error(`No stories found in ${indexPath}.`);
  }

  return stories;
}

async function waitForStoryToSettle(page) {
  await page.waitForSelector(`#storybook-root`, { state: `attached` });
  await page.waitForFunction(
    () => document.querySelector(`#storybook-root`)?.childNodes.length > 0,
  );
  await page.evaluate(async () => {
    await document.fonts?.ready;
    await Promise.all(
      Array.from(document.images, (image) => {
        if (image.complete) {
          return undefined;
        }

        return new Promise((resolveImage) => {
          image.addEventListener(`load`, resolveImage, { once: true });
          image.addEventListener(`error`, resolveImage, { once: true });
        });
      }),
    );
    await new Promise((resolveAnimationFrame) =>
      requestAnimationFrame(() => requestAnimationFrame(resolveAnimationFrame)),
    );
  });
}

function cleanFileName(value) {
  return (
    String(value)
      .replace(/[^a-z0-9_-]+/gi, `-`)
      .replace(/^-+|-+$/g, ``) || `unnamed`
  );
}

function outputPathFor({ story, viewport }) {
  return join(outputDir, cleanFileName(viewport.name), `${cleanFileName(story.id)}.png`);
}

async function readScreenshotParameters(context, stories, baseUrl) {
  const page = await context.newPage();

  try {
    await page.goto(
      `${baseUrl}/iframe.html?id=${encodeURIComponent(stories[0].id)}&viewMode=story`,
      {
        waitUntil: `domcontentloaded`,
      },
    );
    await page.waitForFunction(
      () => window.__STORYBOOK_PREVIEW__?.storyStoreValue?.loadStory,
    );

    return await page.evaluate(
      async (storyIds) => {
        const cleanViewport = (viewport) => {
          if (!viewport || typeof viewport !== `object`) {
            return undefined;
          }

          const width = Number(viewport.width);
          const height = Number(viewport.height);
          if (
            !Number.isFinite(width) ||
            !Number.isFinite(height) ||
            width <= 0 ||
            height <= 0
          ) {
            return undefined;
          }

          return { width, height };
        };

        const cleanViewportDefinitions = (definitions) => {
          if (!definitions || typeof definitions !== `object`) {
            return {};
          }

          return Object.fromEntries(
            Object.entries(definitions)
              .map(([name, viewport]) => {
                const cleaned = cleanViewport(viewport);
                return cleaned ? [name, cleaned] : undefined;
              })
              .filter(Boolean),
          );
        };

        const cleanScreenshotsAt = (screenshotsAt) => {
          const list =
            typeof screenshotsAt === `string` ? [screenshotsAt] : screenshotsAt;
          if (!Array.isArray(list)) {
            return undefined;
          }

          return list.filter((viewport) => typeof viewport === `string`);
        };

        const store = window.__STORYBOOK_PREVIEW__?.storyStoreValue;
        if (!store?.loadStory) {
          throw new Error(`Storybook preview store is not available.`);
        }

        const entries = [];
        for (const storyId of storyIds) {
          const story = await store.loadStory({ storyId });
          entries.push([
            storyId,
            {
              name: story.name,
              screenshotsAt: cleanScreenshotsAt(story.parameters?.screenshotsAt),
              screenshotViewports: cleanViewportDefinitions(
                story.parameters?.screenshotViewports,
              ),
              title: story.title,
            },
          ]);
        }
        return Object.fromEntries(entries);
      },
      stories.map((story) => story.id),
    );
  } catch (error) {
    throw new Error(
      `Could not read resolved story parameters from the Storybook preview runtime.`,
      {
        cause: error,
      },
    );
  } finally {
    await page.close();
  }
}

function resolveViewport(viewportName, definitions, storyId) {
  const viewport = definitions[viewportName];
  if (viewport) {
    return { ...viewport, name: viewportName };
  }

  throw new Error(
    `Story ${storyId} requested unknown screenshot viewport \`${viewportName}\`. Define it in \`parameters.screenshotViewports\`.`,
  );
}

function createCaptureJobs(stories, runtimeData) {
  const jobs = [];

  for (const story of stories) {
    const runtimeStory = runtimeData[story.id] ?? {};
    const viewportNames = runtimeStory.screenshotsAt ?? [];

    for (const viewportName of viewportNames) {
      jobs.push({
        story: {
          ...story,
          name: runtimeStory.name ?? story.name,
          title: runtimeStory.title ?? story.title,
        },
        viewport: resolveViewport(
          viewportName,
          runtimeStory.screenshotViewports ?? {},
          story.id,
        ),
      });
    }
  }

  return jobs;
}

async function captureScreenshot(page, job, baseUrl) {
  const { story, viewport } = job;
  const iframePath = `/iframe.html?id=${encodeURIComponent(story.id)}&viewMode=story`;
  const outputPath = outputPathFor(job);

  await mkdir(dirname(outputPath), { recursive: true });
  await page.setViewportSize({ width: viewport.width, height: viewport.height });
  await page.goto(`${baseUrl}${iframePath}`, { waitUntil: `domcontentloaded` });
  await page.addStyleTag({ content: disableAnimationsCss });
  await waitForStoryToSettle(page);
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.locator(`#storybook-root`).screenshot({
    animations: `disabled`,
    caret: `hide`,
    path: outputPath,
  });

  writeStdout(
    `Captured ${story.id} @ ${viewport.name} (${viewport.width}x${viewport.height}) -> ${outputPath}`,
  );

  return {
    id: story.id,
    iframePath,
    name: story.name,
    path: relative(process.cwd(), outputPath),
    title: story.title,
    viewport,
  };
}

async function runWorkers(jobs, context, baseUrl) {
  const manifest = new Array(jobs.length);
  const workerCount = Math.min(concurrency, jobs.length);
  let nextJobIndex = 0;

  writeStdout(
    `Capturing ${jobs.length} screenshots with ${workerCount} parallel workers...`,
  );

  await Promise.all(
    Array.from({ length: workerCount }, async () => {
      const page = await context.newPage();
      try {
        while (nextJobIndex < jobs.length) {
          const jobIndex = nextJobIndex;
          nextJobIndex += 1;
          manifest[jobIndex] = await captureScreenshot(page, jobs[jobIndex], baseUrl);
        }
      } finally {
        await page.close();
      }
    }),
  );

  return manifest;
}

async function main() {
  const stories = await readStories();

  const server = await serveStatic(storybookDir);
  const address = server.address();
  const actualPort = typeof address === `object` && address ? address.port : port;
  const baseUrl = `http://${host}:${actualPort}`;
  let browser;

  try {
    browser = await chromium.launch();
    const context = await browser.newContext({
      colorScheme: `light`,
      deviceScaleFactor: 2,
      reducedMotion: `reduce`,
    });

    const runtimeData = await readScreenshotParameters(context, stories, baseUrl);
    const jobs = createCaptureJobs(stories, runtimeData);

    if (jobs.length === 0) {
      throw new Error(
        `No stories opted into screenshots. Add \`parameters: { screenshotsAt: [...] }\` to at least one story or meta.`,
      );
    }

    await rm(outputDir, { recursive: true, force: true });
    await mkdir(outputDir, { recursive: true });

    const manifest = await runWorkers(jobs, context, baseUrl);

    await writeFile(
      join(outputDir, `manifest.json`),
      `${JSON.stringify(manifest, null, 2)}\n`,
    );
    writeStdout(
      `\nCaptured ${jobs.length} screenshots from ${stories.length} stories in ${outputDir}`,
    );
  } finally {
    await browser?.close();
    await new Promise((resolveServer) => server.close(resolveServer));
  }
}

main().catch((error) => {
  process.stderr.write(`${error instanceof Error ? error.stack : error}\n`);
  process.exitCode = 1;
});
