import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { setTimeout as delay } from 'node:timers/promises';
import { chromium } from 'playwright';
import { waitForStoryToSettle } from '../wait-for-story.js';

let browser;

before(async () => {
  browser = await chromium.launch();
});

after(async () => {
  await browser?.close();
});

async function createStory(t, css, status = 200) {
  const page = await browser.newPage();
  page.setDefaultTimeout(2000);
  const response = Promise.withResolvers();
  const requested = Promise.withResolvers();
  t.after(async () => {
    response.resolve();
    await page.close();
  });

  await page.route(`http://storybook.test/**`, async (route) => {
    if (route.request().resourceType() === `document`) {
      await route.fulfill({
        contentType: `text/html`,
        body: `<style>
          #storybook-root, #tile { width: 200px; height: 200px; }
        </style>
        <div id="storybook-root"><div id="tile">Story</div></div>`,
      });
    } else {
      requested.resolve();
      await response.promise;
      await route.fulfill({
        status,
        contentType: `image/svg+xml`,
        body:
          status === 200
            ? `<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10" fill="purple"/></svg>`
            : `Not found`,
      });
    }
  });
  await page.goto(`http://storybook.test/`);
  await page.evaluate(() => document.fonts.ready);
  if (css) {
    await page.addStyleTag({ content: css });
  }
  return { page, requested: requested.promise, release: response.resolve };
}

const backgrounds = {
  root: `#storybook-root { background-image: url('/pattern.svg'); }`,
  descendant: `#tile { background-image: url('/pattern.svg'); }`,
  layers: `#tile { background-image: linear-gradient(transparent, transparent), url('/pattern (dots).svg'); }`,
  before: `#tile::before { content: ''; display: block; width: 20px; height: 20px; background-image: url('/pattern.svg'); }`,
  after: `#tile::after { content: ''; display: block; width: 20px; height: 20px; background-image: url('/pattern.svg'); }`,
};

for (const [name, css] of Object.entries(backgrounds)) {
  test(
    `waits for a delayed ${name} background added after page load`,
    { timeout: 5000 },
    async (t) => {
      const { page, requested, release } = await createStory(t, css);
      await requested;
      const settled = waitForStoryToSettle(page).then(() => `settled`);

      assert.equal(await Promise.race([settled, delay(100, `waiting`)]), `waiting`);
      release();
      assert.equal(await settled, `settled`);
    },
  );
}

test(`waits for content in an initially empty story root`, async (t) => {
  const { page } = await createStory(t, ``);
  await page.evaluate(() => document.querySelector(`#storybook-root`).replaceChildren());
  const settled = waitForStoryToSettle(page).then(() => `settled`);

  assert.equal(await Promise.race([settled, delay(100, `waiting`)]), `waiting`);
  await page.evaluate(() => {
    document.querySelector(`#storybook-root`).textContent = `Ready`;
  });
  assert.equal(await settled, `settled`);
});

test(`settles gradients and inline background images`, async (t) => {
  const { page } = await createStory(
    t,
    `#tile { background-image: linear-gradient(purple, white), url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='1' height='1'/%3E"); }`,
  );

  await waitForStoryToSettle(page);
});

test(`ignores backgrounds on hidden elements and ungenerated pseudo-elements`, async (t) => {
  const { page } = await createStory(
    t,
    `#tile { display: none; background-image: url('/pattern.svg'); }
     #storybook-root::before { background-image: url('/pattern.svg'); }`,
  );

  await waitForStoryToSettle(page);
});

test(`fails instead of capturing a broken background`, async (t) => {
  const { page, release } = await createStory(t, backgrounds.root, 404);
  release();

  await assert.rejects(
    waitForStoryToSettle(page),
    /Could not decode CSS background image: http:\/\/storybook.test\/pattern.svg/,
  );
});

test(`times out instead of hanging on a background that never finishes loading`, async (t) => {
  const { page } = await createStory(t, backgrounds.root);
  page.setDefaultTimeout(200);

  await assert.rejects(waitForStoryToSettle(page), /Timeout 200ms exceeded/);
});
