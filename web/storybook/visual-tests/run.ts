import { existsSync, readFileSync } from 'node:fs';
import puppeteer from 'puppeteer';
import { argosScreenshot } from '@argos-ci/puppeteer';
import { notNullish } from '@shared/ts-utils';
import type { StoryData } from './extract-screenshot-test';
import { extractScreenshotTest } from './extract-screenshot-test';

async function main(): Promise<void> {
  const STORIES_JSON_PATH = `../storybook-static/stories.json`;
  if (!existsSync(STORIES_JSON_PATH)) {
    throw new Error(`No stories.json file found. Did you run \`make build-storybook\`?`);
  }

  const json = readFileSync(STORIES_JSON_PATH, `utf-8`);
  const storybook = JSON.parse(json);
  const allStories: StoryData[] = Object.values(storybook.stories);

  const tests = allStories
    .map((story) => [readFileSync(`../${story.importPath}`, `utf-8`), story] as const)
    .map(([file, story]) => extractScreenshotTest(file, story))
    .filter(notNullish);

  if (!tests.some((t) => t.id === `dashboard-users-suspendfilterrequestform--default`)) {
    throw new Error(`story w/ custom wait not found, possibly renamed`);
  }

  const browser = await puppeteer.launch({ headless: true, product: `chrome` });
  const page = await browser.newPage();
  const url = `http://localhost:4777/${process.env.CI ? `` : `iframe.html`}`;

  // inject css to stabilize screenshots
  await page.evaluateOnNewDocument(() => {
    document.addEventListener(
      `DOMContentLoaded`,
      () => {
        const style = document.createElement(`style`);
        style.type = `text/css`;
        style.innerHTML = `
        * {
           transition: none !important;
           letter-spacing: -0.03em; /* sorta normalize CI fonts vs macOS  */
        }`;
        document.querySelector(`head`)?.appendChild(style);
      },
      false,
    );
  });

  // ensure fonts loaded
  await page.goto(`${url}?id=dashboard-core-gradienticon--grid`);
  await new Promise((resolve) => setTimeout(resolve, 350));
  await page.goto(`${url}?id=dashboard-dashboard-screen--no-users`);
  await new Promise((resolve) => setTimeout(resolve, 350));

  for (const test of tests) {
    process.stderr.write(`story id: ${test.id}, sizes: ${JSON.stringify(test.sizes)}\n`);
    await page.goto(`${url}?id=${test.id}&viewMode=story`);

    for (const size of test.sizes) {
      await page.setViewport({ width: size.width, height: size.height });
      await page.waitForSelector(`#storybook-root > *`);
      if (test.id === `dashboard-users-suspendfilterrequestform--default`) {
        await page.waitForSelector(`ul[role="listbox"]`);
      }
      await argosScreenshot(page, `${test.id}--w${size.width}`, {
        fullPage: true,
      });
    }
  }
  await browser.close();
}

main();
