import { describe, expect, test } from 'vitest';
import type { UnlockRequestRow, UnlockReviewEntry } from '../unlockRequests';
import {
  addressMatchOptions,
  buildUnlockReview,
  denyAllDecisions,
  keyForUnlockRequest,
  planUnlockReview,
  reconcileUnlockReview,
  sanitizeRequestedAddress,
  updateGroupDecision,
  updateGroupKeyAddressMatch,
} from '../unlockRequests';

const request = (
  id: string,
  domain = `${id}.example.com`,
  extra: Partial<UnlockRequestRow> = {},
): UnlockRequestRow => ({
  id,
  domain,
  appName: `Safari`,
  appSlug: `safari`,
  appBundleId: `com.apple.Safari`,
  appCategories: [`browser`],
  createdAt: `2026-07-03T12:00:00Z`,
  ...extra,
});
const groupFor = (entries: UnlockReviewEntry[], id: string) => {
  const group = entries
    .flatMap((entry) => (entry.kind === `web` ? [entry.group] : entry.groups))
    .find((group) => group.requestIds.includes(id));
  if (!group) throw new Error(`Missing request ${id}`);
  return group;
};
const allow = (
  entries: UnlockReviewEntry[],
  id: string,
  match: `exact` | `parent` | `subdomains` = `exact`,
) => {
  const group = groupFor(entries, id);
  Object.assign(group, updateGroupKeyAddressMatch(group, match), {
    decision: `allow`,
    edited: true,
  });
  return group;
};

describe(`unlock review decisions`, () => {
  test(`repetitions and www aliases share one card, but sibling hosts and app scopes do not`, () => {
    const entries = buildUnlockReview([
      request(`root`, `example.com`),
      request(`www`, `WWW.EXAMPLE.COM.`),
      request(`repeat`, `example.com`, { requestComment: `School` }),
      request(`docs`),
      request(`app`, `example.com`, { appCategories: [], appSlug: `scratch` }),
    ]);
    expect(entries).toHaveLength(3);
    expect(groupFor(entries, `root`).requestIds).toEqual([`repeat`, `root`, `www`]);
    expect(groupFor(entries, `www`).target).toBe(`example.com`);
    expect(groupFor(entries, `root`).key).toMatchObject({
      type: `domain`,
      domain: `example.com`,
    });
    expect(
      addressMatchOptions(groupFor(entries, `root`)).map((option) => option.value),
    ).toEqual([`exact`, `subdomains`]);
    expect(addressMatchOptions(groupFor(entries, `docs`))).toEqual([
      { value: `exact`, label: `Only docs.example.com`, domain: `docs.example.com` },
      {
        value: `subdomains`,
        label: `docs.example.com and its subdomains`,
        domain: `docs.example.com`,
      },
      {
        value: `parent`,
        label: `example.com and all its subdomains`,
        domain: `example.com`,
      },
    ]);
  });

  test.each([
    { domain: `docs.example.com`, url: `https://other.example.org/path` },
    { domain: undefined, url: `https://DOCS.example.com./path` },
  ])(`hostname wins over an accompanying IP (%#)`, (fields) => {
    expect(
      keyForUnlockRequest(
        request(`one`, undefined, { ...fields, ipAddress: `192.0.2.1` }),
      ),
    ).toMatchObject({ type: `domain`, domain: `docs.example.com` });
  });

  test.each([undefined, `not a URL`, `mailto:person@example.com`])(
    `IP fallback without a usable host (%s)`,
    (url) => {
      const entries = buildUnlockReview([
        request(`ip`, undefined, { domain: undefined, url, ipAddress: `192.0.2.1` }),
      ]);
      expect(groupFor(entries, `ip`).key).toMatchObject({ type: `ipAddress` });
      expect(groupFor(entries, `ip`).risk?.level).toBe(`caution`);
      expect(addressMatchOptions(groupFor(entries, `ip`))).toEqual([]);
    },
  );

  test.each([`192.0.2.1`, `[2001:db8::1]`])(
    `URL IP literal %s creates an IP key`,
    (host) => {
      expect(
        keyForUnlockRequest(
          request(`ip`, undefined, { domain: undefined, url: `https://${host}/` }),
        ),
      ).toMatchObject({ type: `ipAddress`, ipAddress: host.replace(/^\[|\]$/g, ``) });
    },
  );

  test(`strong risks start denied and remain risky when an IP is present`, () => {
    const entries = buildUnlockReview([
      request(`video`, `youtube.com`, { ipAddress: `192.0.2.1` }),
      request(`docs`),
    ]);
    expect(groupFor(entries, `video`)).toMatchObject({
      decision: `deny`,
      risk: { level: `strongWarning` },
    });
    expect(groupFor(entries, `docs`).decision).toBe(`undecided`);
  });

  test.each([`classroom.google.com`, `school.s3.amazonaws.com`, `school.netlify.app`])(
    `broadening %s updates its warning`,
    (host) => {
      const entries = buildUnlockReview([request(`one`, host)]);
      const original = groupFor(entries, `one`);
      const broad = updateGroupKeyAddressMatch(original, `parent`);
      expect(broad.risk?.level).toBe(`strongWarning`);
      expect(updateGroupKeyAddressMatch(broad, `exact`).risk).toEqual(original.risk);
    },
  );

  test(`broad approval includes only undecided matching requests and restores them when cleared`, () => {
    const entries = buildUnlockReview([
      request(`docs`),
      request(`school`),
      request(`outside`, `other.org`),
    ]);
    const source = allow(entries, `docs`, `parent`);
    let plan = planUnlockReview(entries);
    expect(plan.decisions).toHaveLength(1);
    expect(plan.decisions[0]?.requestIds).toEqual([`docs`, `school`]);
    expect(plan.rows.get(groupFor(entries, `school`).id)?.coveredBy).toEqual([source]);
    expect(groupFor(entries, `school`).decision).toBe(`undecided`);
    Object.assign(source, updateGroupDecision(source, `undecided`));
    plan = planUnlockReview(entries);
    expect(plan.decidedCount).toBe(0);
    expect(plan.decisions).toEqual([]);
  });

  test.each([`keychain`, `note`, `expiration`, `identical`])(
    `explicit approvals are never discarded (%s)`,
    (difference) => {
      const entries = buildUnlockReview([request(`docs`), request(`school`)], `weekend`);
      allow(entries, `docs`, `parent`);
      const target = allow(entries, `school`);
      if (difference === `keychain`) target.keychainId = `always-active`;
      if (difference === `note`) target.comment = `Important private note`;
      if (difference === `expiration`) target.expiration = `2099-01-01T00:00:00Z`;
      const plan = planUnlockReview(entries);
      expect(plan.decisions).toHaveLength(2);
      expect(plan.decisions.flatMap((decision) => decision.requestIds)).toEqual([
        `docs`,
        `school`,
      ]);
      expect(plan.rows.get(target.id)).toMatchObject({
        coveredBy: [],
        coveredRequestCount: 0,
        overlaps: true,
      });
      expect(plan.decisions[1]?.action).toMatchObject({
        keychainId: target.keychainId,
        comment: target.comment,
        expiration: target.expiration,
      });
    },
  );

  test(`equivalent broad approvals stay explicit instead of hiding each other's settings`, () => {
    const entries = buildUnlockReview([request(`docs`), request(`school`)]);
    allow(entries, `docs`, `parent`);
    allow(entries, `school`, `parent`);
    expect(planUnlockReview(entries).decisions).toHaveLength(2);
  });

  test(`denials conflicting with a proposed approval block submission`, () => {
    const entries = buildUnlockReview([request(`docs`), request(`school`)]);
    allow(entries, `docs`, `parent`);
    groupFor(entries, `school`).decision = `deny`;
    const plan = planUnlockReview(entries);
    expect(plan).toMatchObject({ problemCount: 1, decisions: [] });
    expect(plan.rows.get(groupFor(entries, `school`).id)?.problem).toBe(
      `You denied this request, but your approval of example.com and its subdomains would still allow it. Narrow or clear that broader approval to keep this request denied.`,
    );
    allow(entries, `docs`, `exact`);
    expect(planUnlockReview(entries).problemCount).toBe(0);
  });

  test(`an IP approval detects a denied hostname on the same address`, () => {
    const entries = buildUnlockReview([
      request(`ip`, undefined, { domain: undefined, ipAddress: `192.0.2.1` }),
      request(`video`, `youtube.com`, { ipAddress: `192.0.2.1` }),
    ]);
    allow(entries, `ip`);
    expect(planUnlockReview(entries).problemCount).toBe(1);
  });

  test(`app scope and descendant boundaries constrain inclusion`, () => {
    const entries = buildUnlockReview([
      request(`docs`),
      request(`child`, `one.docs.example.com`),
      request(`sibling`, `school.example.com`),
      request(`lookalike`, `notdocs.example.com`),
      request(`app`, `one.docs.example.com`, { appCategories: [], appSlug: `scratch` }),
    ]);
    const source = allow(entries, `docs`, `subdomains`);
    expect(planUnlockReview(entries).decisions[0]?.requestIds).toEqual([`docs`, `child`]);
    source.key = {
      type: `anySubdomain`,
      domain: `docs.example.com`,
      scope: { type: `unrestricted` },
    };
    expect(planUnlockReview(entries).decisions[0]?.requestIds).toEqual([
      `docs`,
      `child`,
      `app`,
    ]);
  });

  test(`invalid explicit approvals cannot be hidden by another approval`, () => {
    const entries = buildUnlockReview([request(`docs`), request(`school`)]);
    allow(entries, `docs`, `parent`);
    allow(entries, `school`).expiration = `2020-01-01T00:00:00Z`;
    expect(planUnlockReview(entries)).toMatchObject({ problemCount: 1, decisions: [] });
  });

  test(`full-app access is one separate override, with individual decisions preserved`, () => {
    const entries = buildUnlockReview([
      request(`app`, undefined, { appCategories: [], appSlug: `scratch` }),
    ]);
    const entry = entries[0];
    if (entry?.kind !== `app`) throw new Error(`Expected app`);
    const group = groupFor(entries, `app`);
    group.decision = `deny`;
    entry.unrestricted = true;
    expect(planUnlockReview(entries).decisions).toEqual([
      { requestIds: [`app`], action: { case: `acceptedApp`, scope: entry.scope } },
    ]);
    entry.unrestricted = false;
    expect(planUnlockReview(entries).decisions).toEqual([
      { requestIds: [`app`], action: { case: `rejected` } },
    ]);
  });

  test(`clearing an approval resets its settings without changing its destination`, () => {
    const entries = buildUnlockReview([request(`docs`)], `school`);
    const group = allow(entries, `docs`, `parent`);
    group.comment = `Old note`;
    group.expiration = `2099-01-01T00:00:00Z`;
    const cleared = updateGroupDecision(group, `undecided`, `school`);
    expect(cleared).toMatchObject({
      decision: `undecided`,
      key: { type: `domain`, domain: `docs.example.com` },
      comment: undefined,
      expiration: undefined,
      keychainId: `school`,
    });
  });

  test(`refresh preserves decisions and settings, adds new requests, and removes resolved IDs`, () => {
    const entries = buildUnlockReview([request(`docs`), request(`resolved`)], `personal`);
    const source = allow(entries, `docs`);
    source.comment = `Do not lose this`;
    source.keychainId = `school`;
    const refreshed = reconcileUnlockReview(
      entries,
      [request(`docs`), request(`alias`, `www.docs.example.com`), request(`new`)],
      `personal`,
    );
    expect(groupFor(refreshed, `docs`)).toMatchObject({
      decision: `allow`,
      keychainId: `school`,
      comment: `Do not lose this`,
      requestIds: [`docs`, `alias`],
    });
    expect(groupFor(refreshed, `new`)).toMatchObject({
      decision: `undecided`,
      keychainId: `personal`,
    });
    expect(refreshed).toHaveLength(2);
    expect(reconcileUnlockReview(refreshed, [], `personal`)).toEqual([]);
  });

  test(`deny all ignores proposed grants, and URL details hide secrets`, () => {
    const entries = buildUnlockReview([request(`docs`), request(`school`)]);
    allow(entries, `docs`, `parent`);
    expect(denyAllDecisions(entries)).toEqual([
      { requestIds: [`docs`, `school`], action: { case: `rejected` } },
    ]);
    expect(
      sanitizeRequestedAddress(
        request(`one`, undefined, {
          url: `https://user:secret@school.example.com/lesson?secret=yes#token`,
        }),
      ),
    ).toBe(`school.example.com/lesson`);
  });
});
