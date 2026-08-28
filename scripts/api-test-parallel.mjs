#!/usr/bin/env node
import { spawn, spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const API_DIR = path.join(ROOT, 'swift', 'api');
const BUILD_DIR = path.join(API_DIR, '.build');
const SWIFTLY = path.join(
  process.env.SWIFTLY_HOME_DIR || path.join(os.homedir(), '.swiftly'),
  'bin',
  'swiftly',
);
const BUILD_STAMP = path.join(BUILD_DIR, 'parallel-test-build-stamp');
const LIST_CACHE = path.join(BUILD_DIR, 'parallel-test-list.json');
const TIMINGS_CACHE = path.join(BUILD_DIR, 'parallel-test-timings.json');
const TARGET = 'ApiTests';

const args = parseArgs(process.argv.slice(2));
const baseDb =
  process.env.TEST_DATABASE_NAME ||
  readEnvVar(path.join(API_DIR, '.env'), 'TEST_DATABASE_NAME');

buildTests();

const bundle = findBundle() ?? fail(`no .xctest bundle in ${BUILD_DIR}/debug`);
const testingLibs = toolchainTestingLibs();
const suites = groupBySuite(listTests(bundle), args.filter);
if (suites.length === 0)
  fail(`no tests matched${args.filter ? ` /${args.filter}/` : ''}`);

const workers = Math.min(args.workers, suites.length);
const shardDbs = Array.from({ length: workers }, (_, i) => `${baseDb}_p${i + 1}`);
// postgres truncates identifiers past 63 bytes, which would silently put two
// shards on the same database
if (shardDbs.some((db) => db.length > 63)) {
  fail(`TEST_DATABASE_NAME "${baseDb}" is too long to derive per-shard databases from`);
}
ensureDatabases(shardDbs);

const shards = shardSuites(suites, workers);
const startedAt = Date.now();
const runs = await Promise.all(shards.map(runShard));
report(runs, Date.now() - startedAt);

// args + env

function parseArgs(argv) {
  const parsed = {
    workers: null,
    filter: null,
    verbose: false,
    build: 'auto',
    shuffle: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--workers' || arg === '-j') parsed.workers = Number(argv[++i]);
    else if (arg.startsWith('--workers=')) parsed.workers = Number(arg.slice(10));
    else if (arg === '--filter') parsed.filter = argv[++i];
    else if (arg.startsWith('--filter=')) parsed.filter = arg.slice(9);
    else if (arg === '--build') parsed.build = 'always';
    else if (arg === '--skip-build') parsed.build = 'never';
    else if (arg === '--verbose' || arg === '-v') parsed.verbose = true;
    else if (arg === '--shuffle') parsed.shuffle = true;
    else {
      fail(
        `unknown argument: ${arg}\nusage: api-test-parallel [--workers N] ` +
          '[--filter REGEX] [--build|--skip-build] [--shuffle] [--verbose]',
      );
    }
  }
  parsed.workers ||= Number(process.env.API_TEST_WORKERS) || defaultWorkers();
  // narrowing to a filter means you're debugging — show passing output too
  parsed.verbose ||= parsed.filter !== null;
  return parsed;
}

// every shard is a process holding its own postgres connection pool, so the
// ceiling here is `max_connections`, not core count
function defaultWorkers() {
  return Math.max(2, Math.min(8, os.cpus().length - 2));
}

function readEnvVar(file, key) {
  const line = fs
    .readFileSync(file, 'utf8')
    .split('\n')
    .filter((line) => line.startsWith(`${key}=`))
    .pop();
  if (!line) fail(`missing ${key} in ${file}`);
  return line.slice(key.length + 1).trim();
}

function toolchainTestingLibs() {
  const located = spawnSync(SWIFTLY, ['use', '--print-location'], { encoding: 'utf8' });
  const dir = located.stdout
    ?.split('\n')
    .map((line) => line.trim())
    .filter((line) => line.startsWith('/'))
    .pop();
  if (!dir) fail(`could not locate the active swift toolchain:\n${located.stderr}`);
  return path.join(dir, 'usr', 'lib', 'swift', 'macosx', 'testing');
}

// build + discovery

function buildTests() {
  if (args.build === 'never') return;
  if (args.build === 'auto' && isBuildCurrent()) return;
  const startedAt = Date.now() / 1000;
  const built = spawnSync(SWIFTLY, ['run', 'swift', 'build', '--build-tests'], {
    cwd: API_DIR,
    stdio: 'inherit',
  });
  if (built.status !== 0) process.exit(built.status ?? 1);
  fs.writeFileSync(BUILD_STAMP, '');
  // stamp when the build *started*, so an edit made mid-build isn't swallowed
  fs.utimesSync(BUILD_STAMP, startedAt, startedAt);
}

// a no-op `swift build --build-tests` can cost several seconds, most of a parallel
// run, so skip it when no build input has changed since our last successful build.
// keyed on our own stamp rather than the bundle's mtime, which llbuild leaves alone
// when a rebuild produces identical output
function isBuildCurrent() {
  let builtAt;
  try {
    builtAt = fs.statSync(BUILD_STAMP).mtimeMs;
  } catch {
    return false;
  }
  if (!findBundle()) return false;
  const manifest = fs.readFileSync(path.join(API_DIR, 'Package.swift'), 'utf8');
  const packages = [
    API_DIR,
    ...[...manifest.matchAll(/\.package\(path: "([^"]+)"\)/g)].map((match) =>
      path.resolve(API_DIR, match[1]),
    ),
  ];
  for (const dir of packages) {
    for (const input of ['Package.swift', 'Package.resolved', 'Sources', 'Tests']) {
      if (newestMtime(path.join(dir, input)) > builtAt) return false;
    }
  }
  return true;
}

function newestMtime(target) {
  let stat;
  try {
    stat = fs.statSync(target);
  } catch {
    return 0;
  }
  if (!stat.isDirectory()) return stat.mtimeMs;
  let newest = stat.mtimeMs;
  for (const entry of fs.readdirSync(target, { withFileTypes: true })) {
    if (entry.name.startsWith('.')) continue;
    newest = Math.max(newest, newestMtime(path.join(target, entry.name)));
  }
  return newest;
}

function findBundle() {
  const dir = path.join(BUILD_DIR, 'debug');
  let name;
  try {
    name = fs.readdirSync(dir).find((entry) => entry.endsWith('.xctest'));
  } catch {}
  if (!name) return null;
  const bundle = path.join(dir, name);
  return {
    path: bundle,
    binary: path.join(bundle, 'Contents', 'MacOS', name.replace('.xctest', '')),
  };
}

// `swift test list` costs ~4s, so cache it against the test binary's mtime
function listTests(bundle) {
  const mtimeMs = fs.statSync(bundle.binary).mtimeMs;
  try {
    const cached = JSON.parse(fs.readFileSync(LIST_CACHE, 'utf8'));
    if (cached.mtimeMs === mtimeMs) return cached.specifiers;
  } catch {}
  const listed = spawnSync(SWIFTLY, ['run', 'swift', 'test', 'list', '--skip-build'], {
    cwd: API_DIR,
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
  });
  if (listed.status !== 0) fail(`failed to list tests:\n${listed.stderr}`);
  const specifiers = listed.stdout
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line.startsWith(`${TARGET}.`));
  fs.writeFileSync(LIST_CACHE, JSON.stringify({ mtimeMs, specifiers }));
  return specifiers;
}

// a suite is one schedulable unit: an XCTest class, or a swift-testing test/suite
// (which `swift test list` prints with a trailing `()` and no `Class/method` shape)
function groupBySuite(specifiers, filter) {
  const pattern = filter ? new RegExp(filter) : null;
  const suites = new Map();
  for (const specifier of specifiers) {
    const xctest = !specifier.endsWith(')');
    const slash = specifier.indexOf('/');
    const name =
      xctest && slash > 0 ? specifier.slice(TARGET.length + 1, slash) : specifier;
    const entry = suites.get(name) ?? { name, xctest, total: 0, selected: [] };
    entry.total += 1;
    if (!pattern || pattern.test(specifier)) entry.selected.push(specifier);
    suites.set(name, entry);
  }
  return [...suites.values()].filter((entry) => entry.selected.length > 0);
}

// scheduling

function readTimings() {
  try {
    return JSON.parse(fs.readFileSync(TIMINGS_CACHE, 'utf8'));
  } catch {
    return {};
  }
}

// longest-processing-time-first bin packing over whole suites, weighted by the
// previous run's measured time when we have it. `--shuffle` throws the balancing
// away to deal suites out at random instead — a way to hunt for tests that only
// pass because some other class seeded a row for them
function shardSuites(suites, count) {
  const timings = readTimings();
  const weighted = suites.map((suite) => ({
    ...suite,
    weight: timings[suite.name] ?? suite.selected.length * 0.05,
  }));
  if (args.shuffle) return dealAtRandom(weighted, count);
  const heaviestFirst = [...weighted].sort((a, b) => b.weight - a.weight);
  const shards = Array.from({ length: count }, () => ({ suites: [], weight: 0 }));
  for (const suite of heaviestFirst) {
    const lightest = shards.reduce((a, b) => (a.weight <= b.weight ? a : b));
    lightest.suites.push(suite);
    lightest.weight += suite.weight;
  }
  return shards.map((shard) => shard.suites).filter((shard) => shard.length > 0);
}

function dealAtRandom(suites, count) {
  const shuffled = [...suites];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  const shards = Array.from({ length: count }, () => []);
  shuffled.forEach((suite, i) => shards[i % count].push(suite));
  return shards.filter((shard) => shard.length > 0);
}

// running

// the bundle's swift-testing tests are reachable through the same `-XCTest`
// list as the xctest classes, so both kinds ride along in one process
function runShard(suites, index) {
  const specifiers = suites.flatMap((suite) =>
    suite.xctest && suite.selected.length === suite.total
      ? [`${TARGET}.${suite.name}`]
      : suite.selected,
  );
  return run({
    label: `shard ${index + 1}`,
    args: ['xctest', '-XCTest', specifiers.join(','), bundle.path],
    env: {
      DYLD_FRAMEWORK_PATH: testingLibs,
      DYLD_LIBRARY_PATH: testingLibs,
      TEST_DATABASE_NAME: shardDbs[index],
    },
    detail: `${suites.length} suite${suites.length === 1 ? '' : 's'}`,
    expected: suites.reduce((sum, suite) => sum + suite.selected.length, 0),
    // rough — the recorded suite times already absorb each process's one-time
    // migration, so this reads a little high. it's here as a reference point:
    // a shard far over its estimate means the machine was busy, not that the
    // tests got slower
    estimate: suites.reduce((sum, suite) => sum + suite.weight, 0),
  });
}

// `script` hands the shard a pty. without one, xctest's structure goes to stderr
// while a test's own `print(...)` sits in a block-buffered stdout that only flushes
// at exit — so debug output would land detached from the test that emitted it
function run({ label, args: commandArgs, env, detail, expected, estimate }) {
  const child = spawn('script', ['-q', '/dev/null', 'xcrun', ...commandArgs], {
    cwd: API_DIR,
    env: {
      ...process.env,
      SWIFT_DETERMINISTIC_HASHING: '1',
      // swift's crash backtracer defaults to `enable=tty`, so the pty switches it
      // on — and symbolicating this bundle takes ~10 minutes. the report already
      // names the test the process died in, which is what we actually need
      SWIFT_BACKTRACE: 'enable=no',
      ...env,
    },
    // `script` reads terminal settings off stdin, and chokes on node's socketpair
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let output = '';
  child.stdout.on('data', (chunk) => (output += chunk));
  child.stderr.on('data', (chunk) => (output += chunk));
  const started = Date.now();
  return new Promise((resolve) => {
    child.on('close', (code) => {
      const elapsed = (Date.now() - started) / 1000;
      // strip the pty's `\r\n` and its echo of the EOF keystroke (`^D` + backspaces)
      output = output.replace(/\r\n/g, '\n').replace(/^(?:\^\w\x08\x08)+/, '');
      process.stdout.write(
        `${code === 0 ? '✓' : '✗'} ${label} — ${detail}, ${elapsed.toFixed(1)}s ` +
          `(est ${estimate.toFixed(1)}s)\n`,
      );
      resolve({
        label,
        code,
        output,
        elapsed,
        expected,
        executed: countExecuted(output),
      });
    });
  });
}

// reporting

function report(runs, elapsedMs) {
  writeTimings(runs);
  const failed = runs.filter((run) => run.code !== 0);
  for (const run of failed) {
    console.log(`\n──────── ${run.label} ────────`);
    console.log(failureReport(run));
  }
  if (args.verbose) for (const run of runs) console.log(run.output.trimEnd());
  const executed = runs.reduce((sum, run) => sum + run.executed, 0);
  const expected = runs.reduce((sum, run) => sum + run.expected, 0);
  const ran =
    executed === expected ? `${executed} tests` : `${executed} of ${expected} tests`;
  const outcome =
    failed.length === 0
      ? 'all passed'
      : `${failed.length} failing shard${failed.length === 1 ? '' : 's'}`;
  console.log(`\n${ran}, ${outcome} in ${(elapsedMs / 1000).toFixed(1)}s`);
  process.exit(failed.length === 0 ? 0 : 1);
}

// xctest interleaves every test's stdout into one stream, so reconstruct the
// per-test blocks and keep only the ones that failed — a passing test's noisy
// (but expected) postgres errors would otherwise read as part of the failure
function failureReport(run) {
  const kept = [];
  let current = null;
  for (const line of run.output.split('\n')) {
    const started = line.match(/^Test Case '(.+)' started\.$/);
    if (started) {
      current = { header: line, body: [] };
      continue;
    }
    const finished = line.match(/^Test Case '.+' (passed|failed) \(/);
    if (finished) {
      if (finished[1] === 'failed') kept.push(current.header, ...current.body, line);
      current = null;
      continue;
    }
    if (current) current.body.push(line);
    else if (isInterestingLine(line)) kept.push(line);
  }
  // a test still open at EOF means the process died inside it
  if (current) {
    kept.push(`${current.header}  ⟵ process exited here`, ...current.body);
  }
  if (run.executed < run.expected) {
    kept.push(
      `\n⚠ ${run.label} stopped early: ${run.expected - run.executed} of ` +
        `${run.expected} tests never ran`,
    );
  }
  return kept.join('\n').trim();
}

// chatter that isn't attributable to any one test
function isInterestingLine(line) {
  if (/^Test Suite '.*' (started|passed)/.test(line)) return false;
  if (/^\s+Executed \d+ tests?, with 0 failures/.test(line)) return false;
  if (/Test run (started|with \d+ tests? in \d+ suites? passed)/.test(line)) return false;
  if (/(Testing Library Version|Target Platform):/.test(line)) return false;
  if (/Test "[^"]*" (started|passed)/.test(line)) return false;
  return true;
}

// counted per test rather than from the suite summaries, which a shard that dies
// mid-run never prints
function countExecuted(output) {
  const xctest = output.match(/^Test Case '.+' (?:passed|failed) \(/gm)?.length ?? 0;
  const swiftTesting = output.match(/Test "[^"]*" (?:passed|failed) after/g)?.length ?? 0;
  return xctest + swiftTesting;
}

function writeTimings(runs) {
  const measured = {};
  for (const run of runs) {
    for (const match of run.output.matchAll(
      /Test Suite '(\w+)' (?:passed|failed).*\n\s+Executed \d+ tests?, with \d+ failures? \(\d+ unexpected\) in [\d.]+ \(([\d.]+)\) seconds/g,
    )) {
      measured[match[1]] = Number(match[2]);
    }
  }
  if (Object.keys(measured).length > 0) {
    fs.writeFileSync(
      TIMINGS_CACHE,
      JSON.stringify({ ...readTimings(), ...measured }, null, 2),
    );
  }
}

// misc

function ensureDatabases(dbs) {
  const listed = spawnSync(
    'psql',
    ['-d', 'postgres', '-tAc', 'select datname from pg_database'],
    {
      encoding: 'utf8',
    },
  );
  if (listed.status !== 0) fail(`failed to query postgres:\n${listed.stderr}`);
  const existing = new Set(listed.stdout.split('\n').map((line) => line.trim()));
  for (const db of dbs.filter((db) => !existing.has(db))) {
    const created = spawnSync('createdb', [db], { encoding: 'utf8' });
    if (created.status !== 0) fail(`failed to create database ${db}:\n${created.stderr}`);
    console.log(`created test database ${db}`);
  }
}

function fail(message) {
  console.error(message);
  process.exit(1);
}
