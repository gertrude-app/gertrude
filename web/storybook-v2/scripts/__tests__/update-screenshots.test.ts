import { spawnSync } from 'node:child_process';
import {
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  writeFileSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { afterEach, beforeEach, expect, test } from 'vitest';

const script = fileURLToPath(new URL(`../update-screenshots.sh`, import.meta.url));
let directory: string;
let output: string;

beforeEach(() => {
  directory = mkdtempSync(join(tmpdir(), `screenshot-wrapper-test-`));
  output = join(directory, `output with spaces`);
  mkdirSync(output);
  writeFileSync(join(output, `old.png`), `old baseline`);
  writeFileSync(
    join(directory, `docker`),
    String.raw`#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');
const args = process.argv.slice(2);
fs.appendFileSync(process.env.TEST_LOG, JSON.stringify(args) + '\n');
const command = args[0];
if (process.env.TEST_FAILURE && [command, args[1]].includes(process.env.TEST_FAILURE)) process.exit(1);
if (command === 'buildx' && args[1] === 'build') {
  fs.writeFileSync(args[args.indexOf('--iidfile') + 1], 'sha256:test-image');
} else if (command === 'create') {
  process.stdout.write('test-container');
} else if (command === 'inspect') {
  process.stdout.write(process.env.TEST_EXIT_CODE || '0');
} else if (command === 'cp') {
  const destination = args[2];
  fs.mkdirSync(destination);
  fs.writeFileSync(path.join(destination, 'new.png'), 'new baseline');
  fs.writeFileSync(path.join(destination, 'manifest.json'), '[]');
}
`,
    { mode: 0o755 },
  );
});

afterEach(() => {
  rmSync(directory, { recursive: true, force: true });
});

function run(environment: Record<string, string> = {}) {
  return spawnSync(`bash`, [script], {
    encoding: `utf8`,
    env: {
      ...process.env,
      PATH: `${directory}:${process.env.PATH}`,
      TMPDIR: directory,
      SCREENSHOT_DIR: output,
      TEST_LOG: join(directory, `docker.log`),
      ...environment,
    },
  });
}

function calls(): string[][] {
  return readFileSync(join(directory, `docker.log`), `utf8`)
    .trim()
    .split(`\n`)
    .map((line) => JSON.parse(line));
}

test(`captures in an isolated ARM64 container and replaces stale screenshots`, () => {
  const result = run({ SCREENSHOT_CONCURRENCY: `2` });

  expect(result.stderr).toBe(``);
  expect(result.status).toBe(0);
  expect(readdirSync(output).sort()).toEqual([`manifest.json`, `new.png`]);
  expect(readFileSync(join(output, `new.png`), `utf8`)).toBe(`new baseline`);
  const build = calls().find((args) => args[0] === `buildx` && args[1] === `build`);
  expect(build).toEqual(expect.arrayContaining([`--platform`, `linux/arm64`, `--load`]));
  const create = calls().find((args) => args[0] === `create`);
  expect(create).toEqual(
    expect.arrayContaining([
      `--platform`,
      `linux/arm64`,
      `--network`,
      `none`,
      `SCREENSHOT_CONCURRENCY=2`,
      `sha256:test-image`,
    ]),
  );
  expect(create).not.toContain(`--volume`);
  expect(create).not.toContain(`--mount`);
  expect(calls().at(-1)).toEqual([`rm`, `--force`, `test-container`]);
  expect(readdirSync(directory).some((name) => name.startsWith(`gertrude-ui-`))).toBe(
    false,
  );
});

test(`defaults to six capture workers`, () => {
  expect(run({ SCREENSHOT_CONCURRENCY: `` }).status).toBe(0);
  expect(calls().find((args) => args[0] === `create`)).toContain(
    `SCREENSHOT_CONCURRENCY=6`,
  );
});

test.each([`info`, `buildx`, `build`, `create`, `start`, `cp`])(
  `preserves the baseline when docker %s fails`,
  (command) => {
    expect(run({ TEST_FAILURE: command }).status).not.toBe(0);
    expect(readdirSync(output)).toEqual([`old.png`]);
    expect(readFileSync(join(output, `old.png`), `utf8`)).toBe(`old baseline`);
    if (command === `start` || command === `cp`) {
      expect(calls().at(-1)).toEqual([`rm`, `--force`, `test-container`]);
    }
  },
);

test(`checks the container exit code even when docker start succeeds`, () => {
  const result = run({ TEST_EXIT_CODE: `17` });

  expect(result.status).not.toBe(0);
  expect(result.stderr).toContain(`exit 17`);
  expect(readdirSync(output)).toEqual([`old.png`]);
  expect(calls().some((args) => args[0] === `cp`)).toBe(false);
  expect(calls().at(-1)).toEqual([`rm`, `--force`, `test-container`]);
});
