import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import puppeteer from 'puppeteer';

interface OgExport {
  storyId: string;
  outPath: string;
  format: `jpeg` | `png`;
  quality?: number;
  width?: number;
  height?: number;
}

const REPO_ROOT = resolve(__dirname, `../../..`);
const STORYBOOK_URL = process.env.STORYBOOK_URL ?? `http://localhost:6006`;
const DEFAULT_WIDTH = 1200;
const DEFAULT_HEIGHT = 627;

const EXPORTS: OgExport[] = [
  {
    storyId: `site-ogimages--site`,
    outPath: `web/site/public/og-images/main.png`,
    format: `png`,
  },
  {
    storyId: `site-ogimages--lockdown-guide`,
    outPath: `web/site/public/og-images/lockdown.en.png`,
    format: `png`,
  },
  {
    storyId: `site-ogimages--five-things`,
    outPath: `web/site/public/og-images/five-things.png`,
    format: `png`,
  },
  {
    storyId: `site-ogimages--gif-app-messages`,
    outPath: `web/site/public/og-images/gif-images.png`,
    format: `png`,
  },
  {
    storyId: `site-ogimages--wicked-project`,
    outPath: `web/site/public/og-images/wicked.png`,
    format: `png`,
  },
];

async function assertStorybookReachable(): Promise<void> {
  try {
    const res = await fetch(`${STORYBOOK_URL}/iframe.html`);
    if (!res.ok) throw new Error(`status ${res.status}`);
  } catch (err) {
    const reason = err instanceof Error ? err.message : String(err);
    process.stderr.write(
      `error: Storybook not reachable at ${STORYBOOK_URL} (${reason})\n` +
        `       run \`just web storybook\` in another terminal, then retry.\n`,
    );
    process.exit(1);
  }
}

async function main(): Promise<void> {
  await assertStorybookReachable();

  const browser = await puppeteer.launch({
    headless: true,
    product: `chrome`,
    args: process.env.CI ? [`--no-sandbox`, `--disable-setuid-sandbox`] : [],
  });
  const page = await browser.newPage();

  await page.evaluateOnNewDocument(() => {
    document.addEventListener(`DOMContentLoaded`, () => {
      const style = document.createElement(`style`);
      style.innerHTML = `* { transition: none !important; animation: none !important; }`;
      document.head.appendChild(style);
    });
  });

  await page.setViewport({
    width: DEFAULT_WIDTH,
    height: DEFAULT_HEIGHT,
    deviceScaleFactor: 2,
  });
  const [warmup] = EXPORTS;
  if (!warmup) throw new Error(`EXPORTS is empty`);
  await page.goto(`${STORYBOOK_URL}/iframe.html?id=${warmup.storyId}&viewMode=story`, {
    waitUntil: `networkidle2`,
    timeout: 30000,
  });
  await page.waitForSelector(`#storybook-root > *`, { timeout: 15000 });
  await new Promise((r) => setTimeout(r, 500));

  for (const exp of EXPORTS) {
    const width = exp.width ?? DEFAULT_WIDTH;
    const height = exp.height ?? DEFAULT_HEIGHT;
    process.stderr.write(`rendering ${exp.storyId} (${width}×${height})\n`);

    await page.setViewport({ width, height, deviceScaleFactor: 2 });
    await page.goto(`${STORYBOOK_URL}/iframe.html?id=${exp.storyId}&viewMode=story`, {
      waitUntil: `networkidle2`,
      timeout: 30000,
    });
    await page.waitForSelector(`#storybook-root > *`, { timeout: 15000 });

    await page.evaluate(() => document.fonts?.ready ?? Promise.resolve());
    await page.evaluate(() =>
      Promise.all(
        Array.from(document.images).map((img) =>
          img.complete
            ? Promise.resolve()
            : new Promise<void>((res) => {
                img.addEventListener(`load`, () => res());
                img.addEventListener(`error`, () => res());
              }),
        ),
      ),
    );
    await new Promise((r) => setTimeout(r, 200));

    const screenshotOptions =
      exp.format === `jpeg`
        ? ({ type: `jpeg`, quality: exp.quality ?? 88 } as const)
        : ({ type: `png` } as const);

    const buffer = await page.screenshot({
      ...screenshotOptions,
      clip: { x: 0, y: 0, width, height },
    });

    const absOut = resolve(REPO_ROOT, exp.outPath);
    await mkdir(dirname(absOut), { recursive: true });
    await writeFile(absOut, buffer);
    process.stderr.write(`  → ${exp.outPath}\n`);
  }

  await browser.close();
}

main().catch((err) => {
  console.error(err); // eslint-disable-line no-console
  process.exit(1);
});
