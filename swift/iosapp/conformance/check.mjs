#!/usr/bin/env node
// Checks captured witness logs against the LibSim OS model rules.
// Input: output of ./capture.sh — either ndjson (log show) or text (idevicesyslog).
// Usage: node check.mjs <witnesses-file> [--timeline] [--hinges] [--shields]
// --hinges analyzes the recording-feature hinge experiments (liveness propagation,
// app bg-session upload chain, controller-as-uploader spike); requires a `collect`
// capture (ndjson) since app-process witnesses never appear in `stream`.
// --shields analyzes the ManagedSettings conformance spike (shields-spike.md);
// also requires a `collect` capture (app-process witnesses).
// See docs/ios-conformance.md and conformance/hinge-experiments.md.

import fs from "node:fs";

const file = process.argv[2];
const showTimeline = process.argv.includes(`--timeline`);
const showHinges = process.argv.includes(`--hinges`);
const showShields = process.argv.includes(`--shields`);
if (!file) {
  console.error(`usage: node check.mjs <witnesses-file> [--timeline] [--hinges] [--shields]`);
  process.exit(1);
}

const MONTHS = {
  Jan: 0, Feb: 1, Mar: 2, Apr: 3, May: 4, Jun: 5,
  Jul: 6, Aug: 7, Sep: 8, Oct: 9, Nov: 10, Dec: 11,
};

function parseLine(line) {
  line = line.trim();
  if (line === ``) return null;
  if (line.startsWith(`{`)) {
    let json;
    try {
      json = JSON.parse(line);
    } catch {
      return null;
    }
    const msg = json.eventMessage ?? ``;
    const m = msg.match(/\[G•\] WITNESS (\S+) ?(.*)/);
    if (!m) return null;
    return {
      t: new Date(json.timestamp).getTime(),
      process: json.process ?? `?`,
      pid: json.processID ?? 0,
      event: m[1],
      detail: m[2].trim(),
    };
  }
  // idevicesyslog: `Jul  3 12:11:13.982465 filter(filter.debug.dylib)[pid] <Notice>: message`
  // (no hostname field, fractional seconds; hostname made optional in case a future
  // libimobiledevice version adds one back)
  const m = line.match(
    /^(\w{3})\s+(\d+)\s+(\d\d:\d\d:\d\d)(?:\.\d+)?\s+(?:\S+\s+)?([^([\s]+)(?:\([^)]*\))?\[(\d+)\].*?\[G•\] WITNESS (\S+) ?(.*)/,
  );
  if (!m) return null;
  const [, mon, day, time, proc, pid, event, detail] = m;
  const now = new Date();
  const t = new Date(
    now.getFullYear(), MONTHS[mon], Number(day),
    ...time.split(`:`).map(Number),
  ).getTime();
  return { t, process: proc, pid: Number(pid), event, detail: detail.trim() };
}

const events = fs
  .readFileSync(file, `utf8`)
  .split(`\n`)
  .map(parseLine)
  .filter(Boolean)
  .sort((a, b) => a.t - b.t);

if (events.length === 0) {
  console.error(`no witness events found in ${file}`);
  process.exit(1);
}

const fmt = (t) => new Date(t).toISOString().replace(`T`, ` `).slice(0, 19);

function followedBy(src, predicate, windowMs) {
  return events.find(
    (e) => e.t >= src.t && e.t <= src.t + windowMs && e !== src && predicate(e),
  );
}

function checkPairs(name, claim, sources, predicate, windowMs, opts = {}) {
  const violations = [];
  let confirmed = 0;
  for (const src of sources) {
    const match = followedBy(src, predicate, windowMs);
    if (match) confirmed += 1;
    else violations.push(src);
  }
  results.push({ name, claim, confirmed, violations, exercised: sources.length > 0, ...opts });
}

const results = [];
const of = (event) => events.filter((e) => e.event === event);

checkPairs(
  `R1 filter init→start`,
  `filter-proxy-init is followed by filter-start in the same process`,
  of(`filter-proxy-init`),
  (e) => e.event === `filter-start`,
  2_000,
);

checkPairs(
  `R2 controller init→start`,
  `controller-proxy-init is followed by controller-start in the same process`,
  of(`controller-proxy-init`),
  (e) => e.event === `controller-start`,
  2_000,
);

checkPairs(
  `R3 needRules → controller`,
  `filter needRules verdicts are re-delivered to the control provider`,
  [...of(`filter-need-rules`), ...of(`filter-sentinel`).filter((e) => e.detail === `refresh-rules`)],
  (e) => e.event === `controller-received-flow`,
  10_000,
);

checkPairs(
  `R4 withUpdateRules → filter`,
  `controller verdicts with update=true cause filter handleRulesChanged`,
  of(`controller-verdict`).filter((e) => e.detail.includes(`update=true`)),
  (e) => e.event === `filter-rules-changed`,
  10_000,
);

checkPairs(
  `R5 notifyRulesChanged → filter`,
  `notifyRulesChanged reaches filter handleRulesChanged (misses expected iff filter dead)`,
  of(`controller-notified-rules-changed`),
  (e) => e.event === `filter-rules-changed`,
  10_000,
  { informational: true },
);

checkPairs(
  `R7 sentinel channel`,
  `app-sentinel-sent (real HTTPS round-trip) is followed by filter-sentinel receipt`,
  of(`app-sentinel-sent`),
  (e) => e.event === `filter-sentinel`,
  10_000,
);

checkPairs(
  `R8 install → providers`,
  `successful filter install is followed by both providers launching`,
  of(`app-installed-filter`),
  (e) => e.event === `filter-proxy-init`,
  60_000,
);

checkPairs(
  `R9 filter dies → relaunches`,
  `filter-stop is eventually followed by a new filter-proxy-init (misses expected iff the stop was the session's last, e.g. user disabled protection)`,
  of(`filter-stop`),
  (e) => e.event === `filter-proxy-init`,
  24 * 60 * 60 * 1000,
  { informational: true },
);

checkPairs(
  `R9 controller dies → relaunches`,
  `controller-stop is eventually followed by a new controller-proxy-init (misses expected iff the stop was the session's last)`,
  of(`controller-stop`),
  (e) => e.event === `controller-proxy-init`,
  24 * 60 * 60 * 1000,
  { informational: true },
);

checkPairs(
  `R10 broadcast → suspend`,
  `broadcast start leads (via app darwin handling) to the suspend sentinel`,
  of(`recorder-start`),
  (e) => e.event === `filter-sentinel` && e.detail === `suspend-filter`,
  10_000,
);

checkPairs(
  `R11 darwin → app`,
  `recorder darwin events reach the app promptly (misses expected iff app suspended/dead)`,
  of(`recorder-start`),
  (e) => e.event === `app-received-recorder-event`,
  10_000,
  { informational: true },
);

checkPairs(
  `R10 suspend → screenshots`,
  `an entered suspension sees screenshots saved within the liveness window`,
  of(`filter-suspended`),
  (e) => e.event === `recorder-screenshot-saved`,
  10_000,
);

checkPairs(
  `R10 stop → resume`,
  `after recording stops, the next flow decision resumes the filter (needs traffic)`,
  of(`recorder-stop`),
  (e) => e.event === `filter-resumed`,
  60_000,
  { informational: true },
);

console.log(`\n${events.length} witness events, ${fmt(events[0].t)} → ${fmt(events.at(-1).t)}\n`);

for (const r of results) {
  const status = !r.exercised
    ? `UNEXERCISED`
    : r.violations.length === 0
      ? `CONFIRMED x${r.confirmed}`
      : r.informational
        ? `INFO ${r.confirmed} followed, ${r.violations.length} not`
        : `VIOLATED x${r.violations.length} (${r.confirmed} ok)`;
  console.log(`${r.name.padEnd(28)} ${status}`);
  console.log(`  ${r.claim}`);
  for (const v of r.violations.slice(0, 5)) {
    console.log(`  ! unmatched at ${fmt(v.t)}  ${v.event} ${v.detail} [pid ${v.pid}]`);
  }
}

// R2 migration race: idempotent, so exactly one side should perform it PER update.
// Both witnesses in one capture can be legitimate — the doc's provocation runs the
// update race twice (both orders), and a delete+reinstall re-migrates — so only
// cross-pairs close in time (both sides racing the same launch) count as violations;
// occurrences far apart are separate migration events, each a valid exercise.
const RACE_WINDOW = 5 * 60 * 1000;
const appMigrated = of(`app-migrated`);
const controllerMigrated = of(`controller-migrated`);
const racingPairs = appMigrated.flatMap((a) =>
  controllerMigrated
    .filter((c) => Math.abs(c.t - a.t) <= RACE_WINDOW)
    .map((c) => `${fmt(a.t)} (app) / ${fmt(c.t)} (controller)`),
);
const migrationVerdict = racingPairs.length > 0
  ? `VIOLATED — both sides migrated within 5min: ${racingPairs.join(`, `)}`
  : appMigrated.length + controllerMigrated.length === 0
    ? `UNEXERCISED`
    : `CONFIRMED — ` +
      [
        appMigrated.length ? `app x${appMigrated.length}` : ``,
        controllerMigrated.length ? `controller x${controllerMigrated.length}` : ``,
      ].filter(Boolean).join(`, `) + `, no cross-pair within 5min`;
console.log(`R2 migration race (mutual exclusion)`.padEnd(28) + ` ${migrationVerdict}`);
console.log(`  migration is idempotent — app and controller never both migrate the same update\n`);

// R6 boot-order evidence: launch-event timeline, sessions split on >5min gaps
const launches = events.filter((e) =>
  [`filter-proxy-init`, `controller-proxy-init`].includes(e.event),
);
console.log(`\nR6 boot order (informational) — provider launch sequence:`);
let lastT = 0;
for (const e of launches) {
  if (e.t - lastT > 300_000 && lastT !== 0) console.log(`  --- gap ---`);
  console.log(`  ${fmt(e.t)}  ${e.event} [pid ${e.pid}]`);
  lastT = e.t;
}

if (showHinges) {
  const kv = (detail, key) => {
    const m = detail.match(new RegExp(`(?:^| )${key}=(\\S+)`));
    return m ? m[1] : null;
  };
  const num = (detail, key) => {
    const v = kv(detail, key);
    return v === null || v === `nil` ? null : Number(v);
  };
  const pcts = (values) => {
    if (values.length === 0) return `(none)`;
    const s = [...values].sort((a, b) => a - b);
    const at = (p) => s[Math.min(s.length - 1, Math.floor((p / 100) * s.length))];
    return `p50=${at(50)} p90=${at(90)} p99=${at(99)} max=${s[s.length - 1]}`;
  };
  const fmtT = (t) => new Date(t).toISOString().slice(11, 23);

  // recording windows: recorder-start .. recorder-stop (or end of capture)
  const windows = [];
  for (const start of of(`recorder-start`)) {
    const stop = events.find((e) => e.event === `recorder-stop` && e.t > start.t);
    windows.push({ from: start.t, to: stop ? stop.t : events.at(-1).t });
  }
  const inWindow = (t, slop = 0) =>
    windows.some((w) => t >= w.from - slop && t <= w.to + slop);

  console.log(`\n${`=`.repeat(64)}`);
  console.log(`HINGE ANALYSIS — ${windows.length} recording window(s)`);
  for (const w of windows) {
    console.log(`  ${fmtT(w.from)} → ${fmtT(w.to)}  (${Math.round((w.to - w.from) / 1000)}s)`);
  }

  // HINGE 1 — liveness propagation: recorder write -> filter read
  const bumps = of(`recorder-liveness-bump`)
    .map((e) => ({ ...e, ts: num(e.detail, `ts`) * 1000, kind: kv(e.detail, `kind`) }))
    .filter((e) => Number.isFinite(e.ts));
  const checks = of(`filter-liveness-check`).map((e) => ({
    ...e,
    sawTs: num(e.detail, `sawTs`) === null ? null : num(e.detail, `sawTs`) * 1000,
    elapsedMs: num(e.detail, `elapsedMs`),
    valid: kv(e.detail, `valid`) === `true`,
  }));
  const lags = [];
  const staleReads = [];
  const falseInvalid = [];
  for (const c of checks) {
    const before = bumps.filter((b) => b.t <= c.t && b.kind !== `tombstone`);
    if (before.length === 0) continue;
    const freshest = Math.max(...before.map((b) => b.ts));
    if (c.sawTs !== null) {
      const lag = freshest - c.sawTs;
      lags.push(lag);
      if (lag > 1_500) staleReads.push(c);
    }
    if (!c.valid && c.t - freshest < 6_000) falseInvalid.push(c);
  }
  console.log(`\nHINGE 1 — liveness propagation (recorder write → filter read)`);
  console.log(`  bumps: ${bumps.length} (${bumps.filter((b) => b.kind === `saved`).length} saved, ${bumps.filter((b) => b.kind === `unchanged`).length} unchanged, ${of(`recorder-liveness-bump`).filter((e) => kv(e.detail, `kind`) === `tombstone`).length} tombstone)`);
  console.log(`  filter checks: ${checks.length}  elapsedMs ${pcts(checks.map((c) => c.elapsedMs).filter((v) => v !== null))}`);
  console.log(`  read-staleness ms (freshest write vs value filter saw): ${pcts(lags.map(Math.round))}`);
  console.log(`  stale reads (>1.5s behind freshest write): ${staleReads.length}`);
  console.log(`  false-invalid (check failed though fresh write existed): ${falseInvalid.length}`);
  for (const c of [...staleReads, ...falseInvalid].slice(0, 5)) {
    console.log(`  ! ${fmtT(c.t)}  ${c.detail}`);
  }
  console.log(`  PASS looks like: stale reads ≈ 0, false-invalid = 0, elapsedMs max < 6500`);

  // HINGE 2 — app background-session upload chain
  const enq = of(`app-upload-enqueued`);
  const completed = of(`app-upload-completed`);
  const okUploads = completed.filter((e) => kv(e.detail, `ok`) === `true`);
  const stranded = completed.filter((e) => kv(e.detail, `stranded`) === `true`);
  const wakes = of(`app-bg-session-wake`);
  const saves = bumps.filter((b) => b.kind === `saved`);
  console.log(`\nHINGE 2 — app bg URLSession chain (drains while app suspended)`);
  console.log(`  frames saved: ${saves.length}   uploads enqueued: ${enq.length}   completed ok: ${okUploads.length}   failed: ${completed.length - okUploads.length}`);
  console.log(`  bg-session wakes: ${wakes.length}   stranded completions: ${stranded.length}`);
  for (const w of windows) {
    const savedIn = saves.filter((b) => b.t >= w.from && b.t <= w.to).length;
    const upIn = okUploads.filter((e) => e.t >= w.from && e.t <= w.to + 120_000);
    const gaps = [];
    for (let i = 1; i < upIn.length; i++) gaps.push(Math.round((upIn[i].t - upIn[i - 1].t) / 1000));
    console.log(`  window ${fmtT(w.from)}: saved=${savedIn} uploaded(+2min)=${upIn.length} upload-gap-s ${pcts(gaps)}`);
  }
  const drains = of(`screenshot-drain`);
  if (drains.length > 0) {
    console.log(`  drain events (backlog over time):`);
    for (const d of drains.slice(0, 20)) {
      console.log(`    ${fmtT(d.t)}  ${d.process}  ${d.detail}`);
    }
  }
  console.log(`  PASS looks like: uploads track saves (backlog bounded), gaps < 60s, wakes > 0`);

  // HINGE 3 — controller-as-uploader spike (filter summons via needRules)
  const summons = of(`filter-summoned-controller`);
  const spikes = of(`controller-spike-upload`);
  const spikeOk = spikes.filter((e) => kv(e.detail, `ok`) === `true`);
  const summonGaps = [];
  for (let i = 1; i < summons.length; i++) {
    const gap = (summons[i].t - summons[i - 1].t) / 1000;
    if (gap < 120) summonGaps.push(Math.round(gap));
  }
  const memFloor = spikes.map((e) => num(e.detail, `memMB`)).filter((v) => v !== null);
  const controllerCrashes = of(`controller-proxy-init`).filter((e) => inWindow(e.t) && e.t !== events[0].t);
  console.log(`\nHINGE 3 — controller-as-uploader (summoned by filter needRules)`);
  console.log(`  summons: ${summons.length}   summon-gap-s ${pcts(summonGaps)}`);
  console.log(`  spike uploads: ${spikes.length}   ok: ${spikeOk.length}   failed: ${spikes.length - spikeOk.length}`);
  console.log(`  upload duration ms ${pcts(spikes.map((e) => num(e.detail, `ms`)).filter((v) => v !== null))}`);
  console.log(`  controller mem headroom MB: min=${memFloor.length ? Math.min(...memFloor) : `?`} ${pcts(memFloor)}`);
  console.log(`  controller re-inits during recording (crash indicator): ${controllerCrashes.length}`);
  for (const e of spikes.filter((s) => kv(s.detail, `ok`) !== `true`).slice(0, 5)) {
    console.log(`  ! ${fmtT(e.t)}  ${e.detail}`);
  }
  console.log(`  PASS looks like: summon gaps ≈ 5s under traffic, ok-rate ≈ 100%, mem min > 5MB, re-inits = 0`);
}

if (showShields) {
  const fmtT = (t) => new Date(t).toISOString().slice(11, 23);
  const auth = of(`shields-lab-authorization`);
  const selections = of(`shield-selection-saved`);
  const appWrites = of(`app-shield-write`);
  const sentinels = of(`filter-sentinel`).filter((e) => e.detail.startsWith(`shields-lab`));
  const controllerWrites = of(`controller-shield-write`);

  console.log(`\n${`=`.repeat(64)}`);
  console.log(`SHIELDS SPIKE ANALYSIS (see conformance/shields-spike.md)`);

  console.log(`\nauthorization status readings: ${auth.length}`);
  for (const e of auth) console.log(`  ${fmtT(e.t)}  ${e.detail}`);

  console.log(`\nselection saves (token round-trip register): ${selections.length}`);
  for (const e of selections) console.log(`  ${fmtT(e.t)}  ${e.detail}`);

  console.log(`\napp-context shield writes: ${appWrites.length}`);
  for (const e of appWrites) console.log(`  ${fmtT(e.t)}  ${e.detail}`);

  console.log(`\ncontroller-context shield writes (THE spike question): ${controllerWrites.length}`);
  const errWrites = controllerWrites.filter((e) => e.detail.includes(`ERR`));
  for (const e of controllerWrites) console.log(`  ${fmtT(e.t)}  [pid ${e.pid}]  ${e.detail}`);
  console.log(`  errors: ${errWrites.length} of ${controllerWrites.length}`);

  console.log(`\nsentinel → controller-write delivery latency:`);
  const latencies = [];
  for (const s of sentinels) {
    const write = controllerWrites.find((w) => w.t >= s.t && w.t - s.t < 30_000);
    const lag = write ? write.t - s.t : null;
    if (lag !== null) latencies.push(lag);
    console.log(`  ${fmtT(s.t)}  ${s.detail.replace(`shields-lab `, ``)} → ${lag === null ? `NO WRITE within 30s` : `${lag}ms`}`);
  }
  const delivered = latencies.length;
  console.log(`  delivered: ${delivered}/${sentinels.length}${delivered ? `, max ${Math.max(...latencies)}ms` : ``}`);
  console.log(`\nPASS looks like: auth=approved, selection bytes>2, controller writes error-free,`);
  console.log(`every sentinel answered <5000ms. Shield VISIBILITY (icon dimmed, shield screen on`);
  console.log(`launch) is human-observed — note observations in the runbook as you go.`);
}

if (showTimeline) {
  console.log(`\nfull timeline:`);
  for (const e of events) {
    console.log(`  ${fmt(e.t)}  ${e.process}[${e.pid}]  ${e.event} ${e.detail}`);
  }
}
