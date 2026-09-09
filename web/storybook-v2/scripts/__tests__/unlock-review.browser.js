import assert from 'node:assert/strict';
import { resolve } from 'node:path';
import { after, before, test } from 'node:test';
import { chromium } from 'playwright';
import { serveStorybook } from '../serve-storybook.js';
import { waitForStoryToSettle } from '../wait-for-story.js';

let browser;
let server;

before(async () => {
  server = await serveStorybook(resolve(process.env.STORYBOOK_DIR ?? `storybook-static`));
  browser = await chromium.launch();
});

after(async () => {
  await browser?.close();
  await server?.close();
});

const cardFor = (page, host, app = `web browsers`) =>
  page.getByRole(`group`, { name: `Request for ${host} in ${app}`, exact: true });

async function openStory(t, width, suffix, component = false) {
  const page = await browser.newPage({
    viewport: { width, height: 900 },
    timezoneId: `UTC`,
    reducedMotion: `reduce`,
  });
  const errors = [];
  page.on(`pageerror`, (error) => errors.push(error.message));
  page.on(`console`, (message) => {
    if (message.type() === `error`) errors.push(message.text());
  });
  t.after(async () => {
    await page.close();
    assert.deepEqual(errors, []);
  });
  page.setDefaultTimeout(5000);
  await page.clock.setFixedTime(new Date(`2026-07-07T12:00:00Z`));
  const storyId = component
    ? `account-components-requests-unlock-request-card--${suffix}`
    : `account-pages-requests--unlock-review${suffix}`;
  await page.goto(`${server.baseUrl}/iframe.html?id=${storyId}&viewMode=story`);
  await waitForStoryToSettle(page);
  assert.equal(
    await page.evaluate(async (storyId) => {
      const story = await window.__STORYBOOK_PREVIEW__.storyStoreValue.loadStory({
        storyId,
      });
      return Boolean(story.playFunction);
    }, storyId),
    false,
    `Visual stories should not run interaction sequences`,
  );
  return page;
}

async function choose(page, card, label, option) {
  await card.getByLabel(label, { exact: true }).click();
  await page.getByRole(`menuitem`, { name: option }).click();
}

async function covered(card, expected) {
  await card
    .getByRole(`button`, { name: /^(Allow request|Deny request|Clear decision)$/ })
    .first()
    .waitFor({
      state: expected ? `hidden` : `visible`,
    });
  if (expected) {
    await card.getByText(`Allowed by`, { exact: true }).waitFor();
    assert.equal(await card.getByRole(`button`).count(), 0);
    assert.equal(await card.locator(`svg`).count(), 0);
  }
}

for (const width of [390, 1440]) {
  test(`clearing seeded or manually customized approvals makes re-approval start with defaults (${width}px)`, async (t) => {
    const page = await openStory(t, width, ``);
    const docs = cardFor(page, `docs.example.com`);
    const school = cardFor(page, `school.example.com`);
    await covered(school, true);
    await docs.getByRole(`button`, { name: `Clear decision`, exact: true }).click();
    await covered(school, false);
    await docs.getByRole(`button`, { name: `Allow request`, exact: true }).click();
    await docs.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    assert.equal(
      await docs.getByLabel(`Allow access to`, { exact: true }).innerText(),
      `Only docs.example.com`,
    );
    await covered(school, false);
    await school.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    assert.equal(
      await school.getByLabel(`Allow access to`, { exact: true }).innerText(),
      `Only school.example.com`,
    );
    assert.equal(
      await school.getByLabel(`Private note`, { exact: true }).inputValue(),
      `For homework.`,
    );

    await docs.getByLabel(`Private note`, { exact: true }).fill(`Temporary draft`);
    await choose(page, docs, `Save to keychain`, `Games`);
    await choose(page, docs, `Works in`, `All apps`);
    await choose(page, docs, `Allow access to`, `example.com and all its subdomains`);
    await covered(school, true);
    await docs.getByRole(`button`, { name: `Clear decision`, exact: true }).click();
    await school.getByLabel(`Private note`, { exact: true }).waitFor();
    assert.equal(
      await school.getByLabel(`Private note`, { exact: true }).inputValue(),
      `For homework.`,
    );
    await docs.getByRole(`button`, { name: `Allow request`, exact: true }).click();
    await docs.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    assert.equal(
      await docs.getByLabel(`Allow access to`, { exact: true }).innerText(),
      `Only docs.example.com`,
    );
    assert.equal(
      await docs.getByLabel(`Works in`, { exact: true }).innerText(),
      `Web browsers`,
    );
    assert.equal(
      await docs.getByLabel(`Save to keychain`, { exact: true }).innerText(),
      `School stuff`,
    );
    assert.equal(await docs.getByLabel(`Private note`, { exact: true }).inputValue(), ``);
    await covered(school, false);
  });

  test(`matching, app scope, partial coverage, and restored drafts (${width}px)`, async (t) => {
    const page = await openStory(t, width, ``);
    const docs = cardFor(page, `docs.example.com`);
    const school = cardFor(page, `school.example.com`);
    const lesson = cardFor(page, `lesson.docs.example.com`);
    const discord = cardFor(page, `support.example.com`, `Discord`);
    const partial = cardFor(page, `class.example.org`);
    await covered(lesson, true);
    await covered(school, true);
    await school.getByText(`Allowed by`, { exact: true }).waitFor();
    const sourceLink = school.getByRole(`link`, {
      name: `example.com and its subdomains`,
      exact: true,
    });
    assert.equal(
      decodeURIComponent((await sourceLink.getAttribute(`href`)).slice(1)),
      await docs.getAttribute(`id`),
    );
    await sourceLink.click();
    await partial.getByText(`1 of 2 requests allowed by`).waitFor();
    await covered(discord, false);

    await docs.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    await choose(page, docs, `Allow access to`, `Only docs.example.com`);
    await covered(lesson, false);
    await school.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    assert.equal(
      await school.getByLabel(`Private note`, { exact: true }).inputValue(),
      `For homework.`,
    );
    await choose(page, school, `Save to keychain`, `Games`);
    await choose(page, docs, `Allow access to`, `docs.example.com and its subdomains`);
    await covered(lesson, true);
    await covered(school, false);

    await choose(page, docs, `Allow access to`, `example.com and all its subdomains`);
    await covered(school, true);
    await school.getByLabel(`Private note`, { exact: true }).waitFor({ state: `hidden` });
    await covered(discord, false);
    await choose(page, docs, `Works in`, `All apps`);
    await covered(discord, true);
    await choose(page, docs, `Works in`, `Web browsers`);
    await covered(discord, false);

    await choose(page, docs, `Allow access to`, `Only docs.example.com`);
    await covered(school, false);
    await covered(lesson, false);
    await school.getByLabel(`Private note`, { exact: true }).waitFor();
    assert.equal(
      await school.getByLabel(`Private note`, { exact: true }).inputValue(),
      `For homework.`,
    );
    assert.equal(
      await school.getByLabel(`Save to keychain`, { exact: true }).innerText(),
      `Games`,
    );
    await school.getByLabel(`Private note`, { exact: true }).fill(`For geometry class`);
    await choose(page, docs, `Allow access to`, `example.com and all its subdomains`);
    await covered(school, true);
    await choose(page, docs, `Allow access to`, `Only docs.example.com`);
    await school.getByLabel(`Private note`, { exact: true }).waitFor();
    assert.equal(
      await school.getByLabel(`Private note`, { exact: true }).inputValue(),
      `For geometry class`,
    );

    await choose(page, school, `Works in`, `All apps`);
    await choose(page, docs, `Allow access to`, `example.com and all its subdomains`);
    await school.getByText(`Your broader approval is kept.`).waitFor();
    await covered(school, false);
    await choose(page, docs, `Works in`, `All apps`);
    await covered(school, true);
    await choose(page, docs, `Allow access to`, `Only docs.example.com`);
    await school.getByLabel(`Works in`, { exact: true }).waitFor();
    assert.equal(
      await school.getByLabel(`Works in`, { exact: true }).innerText(),
      `All apps`,
    );

    const safari = cardFor(page, `other.example.org`, `Safari`);
    await safari.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    await choose(page, safari, `Allow access to`, `Only other.example.org`);
    await partial.getByText(`1 of 2 requests allowed by`).waitFor({ state: `hidden` });
    await choose(page, safari, `Allow access to`, `example.org and all its subdomains`);
    await partial.getByText(`1 of 2 requests allowed by`).waitFor();
    await covered(partial, false);
  });

  test(`root options and whole-app access preserve individual drafts (${width}px)`, async (t) => {
    const page = await openStory(t, width, ``);
    const root = cardFor(page, `khanacademy.org`);
    await root.getByRole(`button`, { name: `Allow request`, exact: true }).click();
    await root.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    assert.equal(
      await root.getByLabel(`Allow access to`, { exact: true }).innerText(),
      `Only khanacademy.org`,
    );
    await root.getByLabel(`Allow access to`, { exact: true }).click();
    await page
      .getByRole(`menuitem`, { name: `Only khanacademy.org`, exact: true })
      .waitFor();
    assert.equal(await page.getByRole(`menuitem`).count(), 2);
    await page
      .getByRole(`menuitem`, { name: `Only khanacademy.org`, exact: true })
      .click();

    const safari = page.getByRole(`region`, { name: `Safari requests`, exact: true });
    const target = cardFor(page, `class.example.org`);
    await target.getByText(`1 of 2 requests allowed by`).waitFor();
    const toggle = safari.getByRole(`button`, {
      name: `Grant Safari full internet access`,
      exact: true,
    });
    await toggle.click();
    await safari.getByText(`This gives the app broad access.`).waitFor();
    assert.equal(await safari.locator(`fieldset button`).first().isDisabled(), true);
    await target.getByText(`1 of 2 requests allowed by`).waitFor({ state: `hidden` });
    await toggle.click();
    await safari
      .getByText(`This gives the app broad access.`)
      .waitFor({ state: `hidden` });
    assert.equal(await safari.locator(`fieldset button`).first().isDisabled(), false);
    await target.getByText(`1 of 2 requests allowed by`).waitFor();
    const unknown = page.getByRole(`region`, {
      name: `Unknown app requests`,
      exact: true,
    });
    await unknown.getByText(`Gertrude could not identify this app.`).waitFor();
    assert.equal(await unknown.locator(`fieldset button`).first().isDisabled(), true);
    await unknown
      .getByRole(`button`, {
        name: `Grant Unknown app full internet access`,
        exact: true,
      })
      .click();
    assert.equal(await unknown.locator(`fieldset button`).first().isDisabled(), false);
  });

  test(`app bulk reset discards matching settings before allowing again (${width}px)`, async (t) => {
    const page = await openStory(t, width, ``);
    const safari = page.getByRole(`region`, { name: `Safari requests`, exact: true });
    const source = cardFor(page, `other.example.org`, `Safari`);
    const target = cardFor(page, `class.example.org`);
    await target.getByText(`1 of 2 requests allowed by`).waitFor();
    await source.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    await source.getByLabel(`Private note`, { exact: true }).fill(`Old app approval`);
    await safari.getByRole(`button`, { name: `Respond to all`, exact: true }).click();
    await page.getByRole(`menuitem`, { name: `Reset all to undecided` }).click();
    await source.getByRole(`button`, { name: `Allow request`, exact: true }).waitFor();
    await target.getByText(`1 of 2 requests allowed by`).waitFor({ state: `hidden` });
    await safari.getByRole(`button`, { name: `Respond to all`, exact: true }).click();
    await page.getByRole(`menuitem`, { name: `Allow all requested addresses` }).click();
    await source.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    assert.equal(
      await source.getByLabel(`Allow access to`, { exact: true }).innerText(),
      `Only other.example.org`,
    );
    assert.equal(
      await source.getByLabel(`Works in`, { exact: true }).innerText(),
      `Safari`,
    );
    assert.equal(
      await source.getByLabel(`Private note`, { exact: true }).inputValue(),
      ``,
    );
    await target.getByText(`1 of 2 requests allowed by`).waitFor({ state: `hidden` });
  });

  test(`permission issues block submission until every conflict is resolved (${width}px)`, async (t) => {
    const page = await openStory(t, width, `-permission-issues`);
    const submit = page.getByRole(`button`, { name: `Submit decided`, exact: true });
    await page
      .getByRole(`alert`)
      .getByText(`Resolve 3 permission issues before submitting.`)
      .waitFor();
    assert.equal(await submit.isDisabled(), true);

    await cardFor(page, `school.example.com`)
      .getByRole(`button`, { name: `Allow request`, exact: true })
      .click();
    await page
      .getByRole(`alert`)
      .getByText(`Resolve 2 permission issues before submitting.`)
      .waitFor();

    const permanent = cardFor(page, `school.example.net`);
    await permanent.getByText(`Your longer approval is kept.`).waitFor();
    await covered(permanent, false);
    const temporary = cardFor(page, `docs.example.net`);
    await temporary.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    await temporary.getByLabel(`Expiration date`, { exact: true }).click();
    await page.getByRole(`button`, { name: `Clear`, exact: true }).click();
    await covered(permanent, true);
    await choose(page, temporary, `Allow access to`, `Only docs.example.net`);
    await covered(permanent, false);
    await permanent.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    assert.equal(
      await permanent.getByLabel(`Expiration date`, { exact: true }).innerText(),
      `Choose date...`,
    );

    const expired = cardFor(page, `expired.study.test`);
    await expired.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    await expired.getByLabel(`Expiration date`, { exact: true }).click();
    await page.getByRole(`button`, { name: `Clear`, exact: true }).click();
    await page
      .getByRole(`alert`)
      .getByText(`Resolve 1 permission issue before submitting.`)
      .waitFor();
    const app = cardFor(page, `api.scratch.mit.edu`, `Scratch`);
    await app.getByRole(`button`, { name: `Key settings`, exact: true }).click();
    await choose(page, app, `Works in`, `Scratch`);
    await page.getByRole(`alert`).waitFor({ state: `hidden` });
    assert.equal(await submit.isDisabled(), false);
  });

  test(`settings start open with exact matching, IP differences, and reactive warnings (${width}px)`, async (t) => {
    const page = await openStory(t, width, `settings-and-warnings`, true);
    await page
      .getByRole(`menuitem`, { name: `Only docs.example.com`, exact: true })
      .waitFor();
    assert.equal(await page.getByRole(`menuitem`).count(), 3);
    await page
      .getByRole(`menuitem`, { name: `Only docs.example.com`, exact: true })
      .click();
    const docs = cardFor(page, `docs.example.com`);
    assert.equal(
      await docs.getByLabel(`Allow access to`, { exact: true }).innerText(),
      `Only docs.example.com`,
    );
    const ip = cardFor(page, `192.0.2.1`);
    await ip.getByLabel(`Works in`, { exact: true }).waitFor();
    assert.equal(await ip.getByLabel(`Allow access to`, { exact: true }).count(), 0);
    await ip.getByText(`This is a direct network address`, { exact: false }).waitFor();

    for (const [host, warning, parent] of [
      [
        `school.s3.amazonaws.com`,
        `This allows every site and service hosted under amazonaws.com`,
        `amazonaws.com`,
      ],
      [`classroom.google.com`, `Broad access to all Google services`, `google.com`],
    ]) {
      const card = cardFor(page, host);
      await card.getByText(warning, { exact: false }).waitFor();
      await card.getByRole(`button`, { name: `Key settings`, exact: true }).click();
      await choose(page, card, `Allow access to`, `Only ${host}`);
      await card.getByText(warning, { exact: false }).waitFor({ state: `hidden` });
      await choose(page, card, `Allow access to`, `${parent} and all its subdomains`);
      await card.getByText(warning, { exact: false }).waitFor();
    }
  });

  test(`saving renders an already decided request and disabled submission (${width}px)`, async (t) => {
    const page = await openStory(t, width, `-saving`);
    await cardFor(page, `docs.example.com`)
      .getByRole(`button`, { name: `Key settings`, exact: true })
      .waitFor();
    assert.equal(
      await page
        .getByRole(`button`, { name: `Submit decided`, exact: true })
        .isDisabled(),
      true,
    );
  });
}
