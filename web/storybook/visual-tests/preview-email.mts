#!/usr/bin/env node
/**
 * Render a templated email with SAMPLE DATA to a screenshot — no API or dev server needed.
 *
 * Fills the gap left by `just swift web-email` (which needs the local API running AND
 * renders literal `{{vars}}`). Run it via the just recipe:
 *
 *     just swift preview-email <alias> [--dark] [--mobile]
 *
 * Lives in web/storybook because that package owns the puppeteer dependency. It's a plain
 * .mts run by `node` (type-stripping, Node 22) — no ts-node. It mirrors the layout assembly
 * in swift/api/.../Email/SyncPostmark.swift, and the SAMPLES below mirror the sample models
 * in TestEmail.swift — TestEmail.swift is the source of truth; keep SAMPLES in sync when
 * you add or change a template.
 */
/* eslint-disable no-console -- CLI script; printing paths/usage is its job */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import puppeteer from 'puppeteer';

const EMAIL_DIR = resolve(import.meta.dirname, `../../../swift/api/Sources/Api/Email`);
const LAYOUTS = `${EMAIL_DIR}/Layouts`;
const TEMPLATES = `${EMAIL_DIR}/Templates`;
const LOCAL_DASH = `http://localhost:8081`;

type Layout = `base` | `top-logo` | `personal`;

interface Sample {
  dir: string;
  layout: Layout;
  model: Record<string, string>;
}

const SAMPLES: Record<string, Sample> = {
  'daily-review-digest': {
    dir: `DailyReviewDigest`,
    layout: `top-logo`,
    model: {
      subjectSummary: `12 new screenshots`,
      intro: `Gertrude has new screenshots of Emma and Caleb’s activity, ready for your review:`,
      childRows: [
        `<p class="centered"><strong>Emma</strong>: 8 new screenshots · 23 awaiting review · <a href="${LOCAL_DASH}/children/abc/activity">review →</a></p>`,
        `<p class="centered"><strong>Caleb</strong>: 4 new screenshots · 18 awaiting review · <a href="${LOCAL_DASH}/children/def/activity">review →</a></p>`,
      ].join(`\n`),
      reviewUrl: `${LOCAL_DASH}/children/activity`,
      manageUrl: `${LOCAL_DASH}/settings`,
    },
  },
  'screen-time-warning': {
    dir: `ScreenTimeWarning`,
    layout: `base`,
    model: { childName: `Billy`, computerName: `Test MacBook Pro` },
  },
  'magic-link': {
    dir: `MagicLink`,
    layout: `top-logo`,
    model: { url: `${LOCAL_DASH}/otp/abc-123` },
  },
  'initial-signup': {
    dir: `InitialSignup`,
    layout: `top-logo`,
    model: { dashboardUrl: LOCAL_DASH, token: `abc-123`, redirect: `` },
  },
  'marketing-ios-only-mac-trial': {
    dir: `IosOnlyMacTrial`,
    layout: `personal`,
    model: { deviceFragment: `Franny’s iPhone` },
  },
  'trial-ending-soon': {
    dir: `TrialEndingSoon`,
    layout: `base`,
    model: { length: `21`, remaining: `3` },
  },
  'trial-expired': {
    dir: `TrialExpired`,
    layout: `base`,
    model: { length: `21` },
  },
  'overdue-to-unpaid': {
    dir: `OverdueToUnpaid`,
    layout: `base`,
    model: {},
  },
  'paid-to-overdue': {
    dir: `PaidToOverdue`,
    layout: `base`,
    model: {},
  },
};

function layoutHtml(layout: Layout): string {
  const base = readFileSync(`${LAYOUTS}/base.html`, `utf-8`);
  const baseCss = readFileSync(`${LAYOUTS}/base.css`, `utf-8`);
  if (layout === `top-logo`) {
    const layoutCss = readFileSync(`${LAYOUTS}/top-logo.css`, `utf-8`);
    const inner = readFileSync(`${LAYOUTS}/top-logo.html`, `utf-8`);
    return base
      .replace(`/* CSS_HERE */`, baseCss + layoutCss)
      .replace(`{{{ @content }}}`, inner);
  }
  if (layout === `personal`) {
    return readFileSync(`${LAYOUTS}/personal.html`, `utf-8`);
  }
  return base.replace(`/* CSS_HERE */`, baseCss);
}

function fillMustache(html: string, model: Record<string, string>): string {
  const vars: Record<string, string> = {
    ...model,
    currentYear: `${new Date().getFullYear()}`,
  };
  let out = html.replace(
    /\{\{#(\w+)\}\}([\s\S]*?)\{\{\/\1\}\}/g,
    (_match: string, key: string, inner: string) => {
      const value = vars[key];
      return value ? inner.replace(/\{\{\.\}\}/g, value) : ``;
    },
  );
  for (const [key, value] of Object.entries(vars)) {
    out = out.split(`{{{${key}}}}`).join(value).split(`{{${key}}}`).join(value);
  }
  return out.replace(/\{\{\{?[^}]*\}\}\}?/g, ``); // blank leftover postmark vars, e.g. pm:unsubscribe
}

function assemble(sample: Sample): string {
  const template = readFileSync(`${TEMPLATES}/${sample.dir}/template.html`, `utf-8`);
  const composed = layoutHtml(sample.layout).replace(`{{{ @content }}}`, template);
  return fillMustache(composed, sample.model);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const alias = args.find((arg) => !arg.startsWith(`--`));
  const dark = args.includes(`--dark`);
  const mobile = args.includes(`--mobile`);

  const sample = alias === undefined ? undefined : SAMPLES[alias];
  if (sample === undefined) {
    console.error(`Usage: just swift preview-email <alias> [--dark] [--mobile]\n`);
    console.error(`Known aliases (add more by mirroring TestEmail.swift):`);
    Object.keys(SAMPLES).forEach((known) => console.error(`  • ${known}`));
    process.exit(1);
  }

  const html = assemble(sample);

  const outDir = join(tmpdir(), `email-preview`);
  mkdirSync(outDir, { recursive: true });
  const suffix = `${dark ? `-dark` : ``}${mobile ? `-mobile` : ``}`;
  const htmlPath = join(outDir, `${alias}${suffix}.html`);
  const pngPath = join(outDir, `${alias}${suffix}.png`);
  writeFileSync(htmlPath, html);

  const browser = await puppeteer.launch({
    headless: true,
    product: `chrome`,
    args: process.env[`CI`] ? [`--no-sandbox`, `--disable-setuid-sandbox`] : [],
  });
  const page = await browser.newPage();
  if (dark) {
    await page.emulateMediaFeatures([{ name: `prefers-color-scheme`, value: `dark` }]);
  }
  await page.setViewport(
    mobile
      ? { width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true }
      : { width: 760, height: 900, deviceScaleFactor: 2 },
  );
  await page.setContent(html, { waitUntil: `domcontentloaded` });
  await new Promise((done) => setTimeout(done, 350));
  await page.screenshot({ path: pngPath, fullPage: true });
  await browser.close();

  console.log(`✓ rendered ${alias}${suffix}`);
  console.log(`  html: ${htmlPath}`);
  console.log(`  png:  ${pngPath}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
