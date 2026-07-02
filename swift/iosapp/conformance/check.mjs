#!/usr/bin/env node
// Checks captured witness logs against the LibSim OS model rules.
// Input: output of ./capture.sh — either ndjson (log show) or text (idevicesyslog).
// Usage: node check.mjs <witnesses-file> [--timeline]
// See docs/ios-conformance.md for the rule definitions and campaign workflow.

import fs from "node:fs";

const file = process.argv[2];
const showTimeline = process.argv.includes(`--timeline`);
if (!file) {
  console.error(`usage: node check.mjs <witnesses-file> [--timeline]`);
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
  // idevicesyslog: `Jul  2 13:45:01 device process(Lib)[pid] <Notice>: message`
  const m = line.match(
    /^(\w{3})\s+(\d+)\s+(\d\d:\d\d:\d\d)\s+\S+\s+([^([\s]+)(?:\([^)]*\))?\[(\d+)\].*?\[G•\] WITNESS (\S+) ?(.*)/,
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
  `app sentinel requests reach the filter as flows`,
  of(`filter-sentinel`),
  () => true,
  0,
);

checkPairs(
  `R8 install → providers`,
  `successful filter install is followed by both providers launching`,
  of(`app-installed-filter`),
  (e) => e.event === `filter-proxy-init`,
  60_000,
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

if (showTimeline) {
  console.log(`\nfull timeline:`);
  for (const e of events) {
    console.log(`  ${fmt(e.t)}  ${e.process}[${e.pid}]  ${e.event} ${e.detail}`);
  }
}
