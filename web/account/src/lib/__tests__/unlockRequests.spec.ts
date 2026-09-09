import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest';
import type { UnlockDomainGroup, UnlockReviewEntry } from '../unlockRequests';
import type { GetPersonUnlockRequests } from '@shared/pairql/src/account';
import {
  addressMatchOptions,
  buildUnlockReview,
  decidedRequestCount,
  decisionsForSubmission,
  denyAllDecisions,
  groupAddressMatch,
  keyForUnlockRequest,
  planUnlockReview,
  sanitizeRequestedAddress,
  updateGroupDecision,
  updateGroupKeyAddressMatch,
} from '../unlockRequests';

type Request = GetPersonUnlockRequests.Output[`requests`][number];

const request = (overrides: Partial<Request> = {}): Request => ({
  id: `request-${Math.random()}`,
  domain: `docs.example.com`,
  appName: `Safari`,
  appSlug: `safari`,
  appBundleId: `com.apple.Safari`,
  appCategories: [`browser`],
  createdAt: `2026-07-03T14:05:00Z`,
  ...overrides,
});

const minecraftApp = {
  appName: `Minecraft`,
  appSlug: `minecraft`,
  appBundleId: `com.mojang.minecraft`,
  appCategories: [`game`],
};

const groupFor = (entries: UnlockReviewEntry[], requestId: string): UnlockDomainGroup => {
  const group = entries
    .flatMap((entry) => (entry.kind === `web` ? [entry.group] : entry.groups))
    .find((group) => group.requestIds.includes(requestId));
  if (!group) {
    throw new Error(`No group for ${requestId}`);
  }
  return group;
};

const allow = (
  group: UnlockDomainGroup,
  match: `exact` | `subdomains` | `parent` = `exact`,
): void => {
  Object.assign(group, updateGroupKeyAddressMatch(group, match), { decision: `allow` });
};

const siblingRequests = (): UnlockReviewEntry[] =>
  buildUnlockReview(
    [
      request({ id: `docs`, domain: `docs.example.com` }),
      request({ id: `school`, domain: `school.example.com` }),
    ],
    `school-keychain`,
  );

describe(`unlock request review`, () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(`2026-07-03T15:00:00Z`));
  });
  afterEach(() => vi.useRealTimers());

  test(`keeps sibling hosts separate and groups only repeated addresses in the same scope`, () => {
    const entries = buildUnlockReview([
      request({ id: `one` }),
      request({ id: `school`, domain: `school.example.com` }),
      request({
        id: `two`,
        domain: `DOCS.example.com.`,
        requestComment: `For class`,
        appSlug: `chrome`,
      }),
      request({ id: `app`, ...minecraftApp }),
    ]);
    expect(entries).toHaveLength(3);
    expect(groupFor(entries, `one`)).toMatchObject({
      target: `docs.example.com`,
      requestIds: [`two`, `one`],
      key: { type: `domain`, domain: `docs.example.com`, scope: { type: `webBrowsers` } },
      decision: `undecided`,
    });
    expect(groupFor(entries, `school`).requestIds).toEqual([`school`]);
    expect(groupFor(entries, `app`).requestIds).toEqual([`app`]);
    expect(decisionsForSubmission(entries)).toEqual([]);
  });

  test.each([
    { domain: `docs.example.com`, url: `https://other.example.org/lesson` },
    { domain: undefined, url: `https://DOCS.example.com./lesson` },
  ])(`prefers the domain or URL hostname over an accompanying IP (%#)`, (address) => {
    const entries = buildUnlockReview([request({ ...address, ipAddress: `192.0.2.1` })]);
    expect(entries[0]).toMatchObject({
      kind: `web`,
      group: {
        target: `docs.example.com`,
        key: {
          type: `domain`,
          domain: `docs.example.com`,
          scope: { type: `webBrowsers` },
        },
        decision: `undecided`,
        risk: undefined,
      },
    });
  });

  test.each([
    { domain: `youtube.com` },
    { domain: undefined, url: `https://youtube.com/watch?v=example` },
  ])(`preserves strong hostname warnings when an IP is also present (%#)`, (address) => {
    const entries = buildUnlockReview([request({ ...address, ipAddress: `192.0.2.1` })]);
    expect(entries[0]).toMatchObject({
      kind: `web`,
      group: {
        target: `youtube.com`,
        decision: `deny`,
        risk: { level: `strongWarning` },
      },
    });
    expect(decidedRequestCount(entries)).toBe(1);
  });

  test.each([undefined, `not a URL`, `mailto:person@example.com`])(
    `falls back to an IP key and caution without a usable hostname (url: %s)`,
    (url) => {
      const entries = buildUnlockReview([
        request({ id: `ip`, domain: undefined, url, ipAddress: `192.0.2.1` }),
      ]);
      const group = groupFor(entries, `ip`);
      expect(group).toMatchObject({
        key: { type: `ipAddress`, ipAddress: `192.0.2.1` },
        decision: `undecided`,
        risk: { level: `caution` },
      });
      expect(addressMatchOptions(group)).toEqual([]);
      expect(updateGroupKeyAddressMatch(group, `parent`)).toBe(group);
    },
  );

  test.each([`192.0.2.1`, `[2001:db8::1]`])(
    `treats URL IP literal %s as an IP rather than a domain`,
    (host) => {
      expect(
        keyForUnlockRequest(request({ domain: undefined, url: `https://${host}/` })),
      ).toMatchObject({ type: `ipAddress`, ipAddress: host.replace(/^\[|\]$/g, ``) });
    },
  );

  test.each([
    [`foo.example.com`, [`exact`, `subdomains`, `parent`]],
    [`one.foo.example.co.uk`, [`exact`, `subdomains`, `parent`]],
    [`example.com`, [`exact`, `subdomains`]],
    [`intranet`, [`exact`, `subdomains`]],
  ] as const)(`offers the appropriate matching choices for %s`, (domain, values) => {
    const group = groupFor(buildUnlockReview([request({ id: `one`, domain })]), `one`);
    expect(addressMatchOptions(group).map((option) => option.value)).toEqual(values);
    expect(groupAddressMatch(group)).toBe(`exact`);
    expect(group.key).toMatchObject({ type: `domain`, domain });
  });

  test.each([
    `docs.example.com`,
    `classroom.google.com`,
    `school.s3.amazonaws.com`,
    `school.netlify.app`,
  ])(
    `includes only descendants of %s without changing the requested address or settings`,
    (domain) => {
      const group = groupFor(buildUnlockReview([request({ id: `one`, domain })]), `one`);
      Object.assign(group, {
        decision: `allow`,
        keychainId: `chosen`,
        comment: `For school`,
        expiration: `2026-10-01T00:00:00Z`,
      });
      const descendants = updateGroupKeyAddressMatch(group, `subdomains`);
      expect(descendants).toMatchObject({
        ...group,
        key: { ...group.key, type: `anySubdomain`, domain },
      });
      expect(groupAddressMatch(descendants)).toBe(`subdomains`);
      expect(updateGroupKeyAddressMatch(descendants, `exact`)).toEqual(group);
    },
  );

  test.each([
    [`classroom.google.com`, `google.com`],
    [`school.s3.amazonaws.com`, `amazonaws.com`],
    [`school.netlify.app`, `netlify.app`],
    [`news.reddit.com`, `reddit.com`],
  ])(`updates the warning when explicitly broadening %s to %s`, (domain, parent) => {
    const group = groupFor(buildUnlockReview([request({ id: `one`, domain })]), `one`);
    const broad = updateGroupKeyAddressMatch({ ...group, decision: `allow` }, `parent`);
    expect(broad).toMatchObject({
      target: domain,
      key: { type: `anySubdomain`, domain: parent },
      decision: `allow`,
      risk: { level: `strongWarning` },
    });
    expect(updateGroupKeyAddressMatch(broad, `exact`).risk).toEqual(group.risk);
  });

  test(`the hosting-parent warning takes precedence over a narrower service warning`, () => {
    const group = groupFor(
      buildUnlockReview([request({ id: `one`, domain: `s3.amazonaws.com` })]),
      `one`,
    );
    expect(updateGroupKeyAddressMatch(group, `parent`).risk).toEqual({
      level: `strongWarning`,
      reason: `This allows every site and service hosted under amazonaws.com, not just the requested address.`,
    });
  });

  test(`preserves warnings for a risky requested host when its parent has no warning`, () => {
    const group = groupFor(
      buildUnlockReview([request({ id: `one`, domain: `copilot.microsoft.com` })]),
      `one`,
    );
    expect(updateGroupKeyAddressMatch(group, `parent`).risk).toMatchObject({
      level: `strongWarning`,
    });
  });

  test(`does not group unrelated hostnames sharing an IP`, () => {
    const entries = buildUnlockReview([
      request({ id: `school`, ipAddress: `192.0.2.1` }),
      request({ id: `youtube`, domain: `youtube.com`, ipAddress: `192.0.2.1` }),
    ]);
    expect(entries).toHaveLength(2);
    expect(groupFor(entries, `school`).requestIds).toEqual([`school`]);
  });

  test(`strong service warnings default to deny while cautions stay undecided`, () => {
    const entries = buildUnlockReview([
      request({ id: `youtube`, domain: `youtube.com` }),
      request({ id: `classroom`, domain: `classroom.google.com` }),
      request({ id: `medium`, domain: `medium.com` }),
      request({ id: `ip`, domain: undefined, ipAddress: `192.0.2.1` }),
    ]);
    expect(groupFor(entries, `youtube`).decision).toBe(`deny`);
    for (const id of [`classroom`, `medium`, `ip`]) {
      expect(groupFor(entries, id)).toMatchObject({
        decision: `undecided`,
        risk: { level: `caution` },
      });
    }
    expect(decidedRequestCount(entries)).toBe(1);
  });

  test(`an allowed parent covers siblings and resolves every represented ID once`, () => {
    const entries = buildUnlockReview(
      [
        request({ id: `docs` }),
        request({ id: `school`, domain: `school.example.com` }),
        request({
          id: `school-again`,
          domain: undefined,
          url: `https://school.example.com/lesson`,
        }),
        request({ id: `root`, domain: `example.com` }),
      ],
      `school-keychain`,
    );
    const source = groupFor(entries, `docs`);
    allow(source, `parent`);
    source.comment = `  For class  `;
    source.expiration = `2026-10-01T00:00:00Z`;
    const plan = planUnlockReview(entries);
    expect(plan.rows.get(groupFor(entries, `school`).id)).toMatchObject({
      coveredBy: [source],
      coveredRequestCount: 2,
    });
    expect(plan.decidedCount).toBe(4);
    expect(plan.decisions).toEqual([
      {
        requestIds: [`docs`, `school`, `school-again`, `root`],
        action: {
          case: `acceptedKey`,
          keychainId: `school-keychain`,
          key: source.key,
          comment: `For class`,
          expiration: source.expiration,
        },
      },
    ]);
  });

  test(`descendant matching covers children but not siblings or lookalike suffixes`, () => {
    const entries = buildUnlockReview([
      request({ id: `docs` }),
      ...[
        `one.docs.example.com`,
        `school.example.com`,
        `notdocs.example.com`,
        `docs.example.com.evil.com`,
      ].map((domain) => request({ id: domain, domain })),
    ]);
    allow(groupFor(entries, `docs`), `subdomains`);
    const plan = planUnlockReview(entries);
    expect(plan.decisions[0]?.requestIds).toEqual([`docs`, `one.docs.example.com`]);
    expect(plan.decidedCount).toBe(2);
  });

  test.each([`undecided`, `deny`] as const)(
    `a %s broad draft does not cover other requests`,
    (decision) => {
      const entries = siblingRequests();
      const source = groupFor(entries, `docs`);
      allow(source, `parent`);
      source.decision = decision;
      expect(
        planUnlockReview(entries).rows.get(groupFor(entries, `school`).id)
          ?.coveredRequestCount,
      ).toBe(0);
    },
  );

  test.each([`undecided`, `deny`] as const)(
    `changing an approval to %s discards its settings before a new approval`,
    (decision) => {
      const entries = buildUnlockReview(
        [
          request({
            id: `one`,
            domain: `classroom.google.com`,
            requestComment: `For school`,
          }),
        ],
        `default-keychain`,
      );
      const original = groupFor(entries, `one`);
      const customized = {
        ...updateGroupKeyAddressMatch(original, `parent`),
        decision: `allow` as const,
        key: {
          type: `anySubdomain` as const,
          domain: `google.com`,
          scope: { type: `unrestricted` as const },
        },
        keychainId: `another-keychain`,
        comment: `Old approval`,
        expiration: `2026-07-04T00:00:00Z`,
      };
      expect(customized.risk?.level).toBe(`strongWarning`);
      const reset = updateGroupDecision(customized, decision, `default-keychain`);
      expect(reset).toEqual({
        ...original,
        decision,
        comment: undefined,
        expiration: undefined,
      });
      expect(reset.requests).toBe(original.requests);
      expect(updateGroupDecision(reset, `allow`, `default-keychain`)).toEqual({
        ...reset,
        decision: `allow`,
      });
      expect(customized.key.type).toBe(`anySubdomain`);
    },
  );

  test.each([{ ...minecraftApp }, { domain: undefined, ipAddress: `192.0.2.1` }])(
    `clearing an approval restores the original app scope and address type (%#)`,
    (overrides) => {
      const entries = buildUnlockReview([request({ id: `one`, ...overrides })]);
      const original = groupFor(entries, `one`);
      const customized = {
        ...updateGroupKeyAddressMatch(original, `parent`),
        decision: `allow` as const,
      };
      if (customized.key.type === `skeleton`) throw new Error(`Expected address key`);
      customized.key = { ...customized.key, scope: { type: `unrestricted` } };
      const reset = updateGroupDecision(customized, `undecided`);
      expect(reset.key).toEqual(original.key);
      expect(reset.risk).toEqual(original.risk);
      expect(groupAddressMatch(reset)).toBe(`exact`);
    },
  );

  test(`clearing a source restores the covered card's unmodified draft`, () => {
    const entries = siblingRequests();
    const source = groupFor(entries, `docs`);
    const target = groupFor(entries, `school`);
    Object.assign(target, {
      keychainId: `other-keychain`,
      comment: `Keep this note`,
      expiration: `2026-12-01T00:00:00Z`,
    });
    const original = structuredClone(target);
    allow(source, `parent`);
    expect(planUnlockReview(entries).rows.get(target.id)?.coveredRequestCount).toBe(1);
    expect(target).toEqual(original);
    Object.assign(source, updateGroupDecision(source, `undecided`, `school-keychain`));
    expect(planUnlockReview(entries).rows.get(target.id)?.coveredRequestCount).toBe(0);
    expect(target).toEqual(original);
    expect(decidedRequestCount(entries)).toBe(0);
  });

  test.each([false, true])(
    `a covered denial blocks submission until explicitly resolved (default denial: %s)`,
    (defaultDenial) => {
      const entries = defaultDenial
        ? buildUnlockReview([
            request({ id: `docs`, domain: `music.youtube.com` }),
            request({ id: `school`, domain: `youtube.com` }),
          ])
        : siblingRequests();
      const source = groupFor(entries, `docs`);
      const target = groupFor(entries, `school`);
      if (!defaultDenial) target.decision = `deny`;
      allow(source, `parent`);
      expect(planUnlockReview(entries).rows.get(target.id)?.problem).toContain(
        `Deny conflicts`,
      );
      expect(decisionsForSubmission(entries)).toEqual([]);
      target.decision = `allow`;
      expect(planUnlockReview(entries).problemCount).toBe(0);
      expect(
        decisionsForSubmission(entries).flatMap((decision) => decision.requestIds),
      ).toEqual([`docs`, `school`]);
    },
  );

  test(`narrowing the source preserves the denial rather than silently changing it`, () => {
    const entries = siblingRequests();
    const source = groupFor(entries, `docs`);
    groupFor(entries, `school`).decision = `deny`;
    allow(source, `parent`);
    expect(planUnlockReview(entries).problemCount).toBe(1);
    allow(source, `exact`);
    const plan = planUnlockReview(entries);
    expect(plan.problemCount).toBe(0);
    expect(plan.decisions).toContainEqual({
      requestIds: [`school`],
      action: { case: `rejected` },
    });
  });

  test(`browser permissions do not cover apps, but all-app permissions do`, () => {
    const entries = buildUnlockReview([
      request({ id: `docs` }),
      request({ id: `game`, domain: `school.example.com`, ...minecraftApp }),
    ]);
    const source = groupFor(entries, `docs`);
    const target = groupFor(entries, `game`);
    allow(source, `parent`);
    expect(planUnlockReview(entries).rows.get(target.id)?.coveredRequestCount).toBe(0);
    source.key = {
      type: `anySubdomain`,
      domain: `example.com`,
      scope: { type: `unrestricted` },
    };
    expect(planUnlockReview(entries).rows.get(target.id)?.coveredRequestCount).toBe(1);
  });

  test.each([`slug`, `bundle`] as const)(
    `single-app coverage respects the %s identity`,
    (identity) => {
      const app =
        identity === `slug` ? minecraftApp : { ...minecraftApp, appSlug: undefined };
      const entries = buildUnlockReview([
        request({ id: `source`, ...app }),
        request({ id: `same`, domain: `school.example.com`, ...app }),
        request({
          id: `other`,
          domain: `school.example.com`,
          appCategories: [`game`],
          appSlug: `other`,
          appBundleId: `com.other`,
        }),
      ]);
      const entry = entries[0];
      if (!entry || entry.kind !== `app`) throw new Error(`Expected app`);
      entry.choice = `perAddress`;
      allow(groupFor(entries, `source`), `parent`);
      expect(
        planUnlockReview(entries).rows.get(groupFor(entries, `same`).id)
          ?.coveredRequestCount,
      ).toBe(1);
      expect(
        planUnlockReview(entries).rows.get(groupFor(entries, `other`).id)
          ?.coveredRequestCount,
      ).toBe(0);
    },
  );

  test(`partial scope coverage resolves only the covered repetitions`, () => {
    const entries = buildUnlockReview([
      request({
        id: `source`,
        ...minecraftApp,
        appSlug: `safari`,
        appBundleId: `com.apple.Safari`,
      }),
      request({ id: `safari`, domain: `school.example.com` }),
      request({
        id: `chrome`,
        domain: `school.example.com`,
        appSlug: `chrome`,
        appBundleId: `com.google.Chrome`,
      }),
    ]);
    const app = entries[0];
    if (!app || app.kind !== `app`) throw new Error(`Expected app`);
    app.choice = `perAddress`;
    allow(groupFor(entries, `source`), `parent`);
    const plan = planUnlockReview(entries);
    expect(plan.rows.get(groupFor(entries, `safari`).id)?.coveredRequestCount).toBe(1);
    expect(plan.decidedCount).toBe(2);
    expect(plan.decisions[0]?.requestIds).toEqual([`source`, `safari`]);
    groupFor(entries, `safari`).decision = `deny`;
    expect(planUnlockReview(entries).problemCount).toBe(1);
  });

  test(`an IP permission detects conflicts even when the denied request also has a hostname`, () => {
    const entries = buildUnlockReview([
      request({ id: `ip`, domain: undefined, ipAddress: `192.0.2.1` }),
      request({ id: `domain`, domain: `youtube.com`, ipAddress: `192.0.2.1` }),
    ]);
    groupFor(entries, `ip`).decision = `allow`;
    expect(
      planUnlockReview(entries).rows.get(groupFor(entries, `domain`).id)?.problem,
    ).toContain(`Deny conflicts`);
  });

  test(`equivalent broad approvals choose one source without circular coverage`, () => {
    const entries = siblingRequests();
    allow(groupFor(entries, `docs`), `parent`);
    allow(groupFor(entries, `school`), `parent`);
    const plan = planUnlockReview(entries);
    expect(plan.problemCount).toBe(0);
    expect(plan.decisions).toHaveLength(1);
    expect(plan.rows.get(groupFor(entries, `docs`).id)?.coveredRequestCount).toBe(0);
    expect(plan.rows.get(groupFor(entries, `school`).id)?.coveredRequestCount).toBe(1);
    expect(plan.decisions[0]?.requestIds).toEqual([`docs`, `school`]);
  });

  test(`transitive coverage retains the permission that actually covers every request`, () => {
    const entries = buildUnlockReview([
      request({ id: `narrow`, domain: `docs.example.com` }),
      request({ id: `broad`, domain: `school.example.com` }),
      request({ id: `nested`, domain: `one.docs.example.com` }),
    ]);
    allow(groupFor(entries, `narrow`), `subdomains`);
    allow(groupFor(entries, `broad`), `parent`);
    const plan = planUnlockReview(entries);
    expect(plan.decisions).toHaveLength(1);
    expect(plan.decisions[0]?.requestIds).toEqual([`narrow`, `broad`, `nested`]);
    expect(plan.decisions[0]?.action).toMatchObject({
      key: { type: `anySubdomain`, domain: `example.com` },
    });
  });

  test(`a shorter broad grant does not discard a longer exact grant`, () => {
    const entries = siblingRequests();
    const source = groupFor(entries, `docs`);
    const target = groupFor(entries, `school`);
    allow(source, `parent`);
    source.expiration = `2026-07-04T00:00:00Z`;
    allow(target);
    target.expiration = `2026-08-01T00:00:00Z`;
    const plan = planUnlockReview(entries);
    expect(plan.decisions).toHaveLength(2);
    expect(plan.rows.get(target.id)).toMatchObject({
      coveredRequestCount: 0,
      coveredBy: [],
      preservedApproval: `longer`,
    });
  });

  test(`equivalent permissions retain the longer expiration regardless of row order`, () => {
    const entries = siblingRequests();
    const short = groupFor(entries, `docs`);
    const long = groupFor(entries, `school`);
    allow(short, `parent`);
    allow(long, `parent`);
    short.expiration = `2026-07-04T00:00:00Z`;
    long.expiration = `2026-08-01T00:00:00Z`;
    const plan = planUnlockReview(entries);
    expect(plan.decisions).toHaveLength(1);
    expect(plan.decisions[0]?.action).toMatchObject({ expiration: long.expiration });
    expect(plan.rows.get(short.id)?.coveredBy).toEqual([long]);
  });

  test.each([
    [`exact`, `school-keychain`, `Different note`],
    [`parent`, `school-keychain`, `Different note`],
    [`exact`, `another-keychain`, `Source note`],
    [`parent`, `another-keychain`, `Source note`],
    [`exact`, `another-keychain`, `Different note`],
    [`parent`, `another-keychain`, `Different note`],
  ] as const)(
    `coverage ignores metadata differences and restores drafts (%s, %s, %s)`,
    (match, keychainId, comment) => {
      const entries = siblingRequests();
      const source = groupFor(entries, `docs`);
      const target = groupFor(entries, `school`);
      allow(source, `parent`);
      source.comment = `Source note`;
      allow(target, match);
      target.keychainId = keychainId;
      target.comment = comment;
      const draft = structuredClone(target);
      const plan = planUnlockReview(entries);
      expect(plan.problemCount).toBe(0);
      expect(plan.decisions).toEqual([
        {
          requestIds: [`docs`, `school`],
          action: {
            case: `acceptedKey`,
            key: source.key,
            keychainId: source.keychainId,
            comment: `Source note`,
            expiration: undefined,
          },
        },
      ]);
      expect(plan.rows.get(target.id)).toMatchObject({
        coveredBy: [source],
        coveredRequestCount: 1,
        preservedApproval: undefined,
      });
      expect(target).toEqual(draft);

      source.decision = `undecided`;
      const restored = planUnlockReview(entries);
      expect(target).toEqual(draft);
      expect(restored.rows.get(target.id)?.coveredRequestCount).toBe(0);
      expect(restored.decisions[0]?.action).toMatchObject({
        key: target.key,
        keychainId,
        comment,
      });
    },
  );

  test(`a temporary broad approval does not replace an explicit permanent approval`, () => {
    const entries = siblingRequests();
    const source = groupFor(entries, `docs`);
    const target = groupFor(entries, `school`);
    allow(source, `parent`);
    source.expiration = `2026-07-04T00:00:00Z`;
    allow(target);
    target.keychainId = `another-keychain`;
    target.comment = `Permanent access for school`;
    const plan = planUnlockReview(entries);
    expect(plan.decisions).toHaveLength(2);
    expect(plan.rows.get(target.id)).toMatchObject({
      coveredBy: [],
      coveredRequestCount: 0,
      preservedApproval: `longer`,
    });
    expect(
      plan.decisions.find((decision) => decision.requestIds.includes(`school`))?.action,
    ).toMatchObject({
      key: target.key,
      expiration: undefined,
      keychainId: target.keychainId,
      comment: target.comment,
    });
  });

  test(`browser-only coverage preserves an explicit all-app approval until the source also allows all apps`, () => {
    const entries = siblingRequests();
    const source = groupFor(entries, `docs`);
    const target = groupFor(entries, `school`);
    allow(source, `parent`);
    allow(target);
    target.key = {
      type: `domain`,
      domain: target.target,
      scope: { type: `unrestricted` },
    };
    const draft = structuredClone(target);
    const plan = planUnlockReview(entries);
    expect(plan.decisions).toHaveLength(2);
    expect(plan.rows.get(target.id)).toMatchObject({
      coveredBy: [],
      coveredRequestCount: 0,
      preservedApproval: `broader`,
    });
    source.key = {
      type: `anySubdomain`,
      domain: `example.com`,
      scope: { type: `unrestricted` },
    };
    const covered = planUnlockReview(entries);
    expect(covered.decisions).toHaveLength(1);
    expect(covered.rows.get(target.id)).toMatchObject({
      coveredBy: [source],
      coveredRequestCount: 1,
      preservedApproval: undefined,
    });
    expect(target).toEqual(draft);
  });

  test(`covered approvals point to a source preserving their full duration, not the first matching address`, () => {
    const entries = buildUnlockReview([
      request({ id: `short`, domain: `docs.example.com` }),
      request({ id: `long`, domain: `school.example.com` }),
      request({ id: `target`, domain: `lesson.school.example.com` }),
    ]);
    const short = groupFor(entries, `short`);
    const long = groupFor(entries, `long`);
    const target = groupFor(entries, `target`);
    allow(short, `parent`);
    short.expiration = `2026-07-04T00:00:00Z`;
    allow(long, `subdomains`);
    allow(target);
    const plan = planUnlockReview(entries);
    expect(plan.decisions).toHaveLength(2);
    expect(plan.rows.get(target.id)).toMatchObject({
      coveredBy: [long],
      coveredRequestCount: 1,
    });
    expect(
      plan.decisions.find((decision) => decision.requestIds.includes(`target`)),
    ).toMatchObject({
      requestIds: [`long`, `target`],
      action: { key: long.key, expiration: undefined },
    });
  });

  test.each([`2026-07-03T14:00:00Z`, `2026-07-03T15:00:00Z`, `invalid date`])(
    `expired or invalid expiration %s cannot provide coverage or be submitted`,
    (expiration) => {
      const entries = siblingRequests();
      const source = groupFor(entries, `docs`);
      allow(source, `parent`);
      source.expiration = expiration;
      const plan = planUnlockReview(entries);
      expect(plan.rows.get(source.id)?.problem).toContain(`expired`);
      expect(plan.rows.get(groupFor(entries, `school`).id)?.coveredRequestCount).toBe(0);
      expect(plan.decisions).toEqual([]);
    },
  );

  test(`coverage disappears when its source expires`, () => {
    const entries = siblingRequests();
    const source = groupFor(entries, `docs`);
    allow(source, `parent`);
    source.expiration = `2026-07-03T15:01:00Z`;
    expect(planUnlockReview(entries).decidedCount).toBe(2);
    vi.setSystemTime(new Date(source.expiration));
    const plan = planUnlockReview(entries);
    expect(plan.decidedCount).toBe(1);
    expect(plan.problemCount).toBe(1);
    expect(plan.decisions).toEqual([]);
  });

  test(`does not report an app request accepted by a browsers-only key`, () => {
    const entries = buildUnlockReview([request({ id: `game`, ...minecraftApp })]);
    const app = entries[0];
    if (!app || app.kind !== `app`) throw new Error(`Expected app`);
    app.choice = `perAddress`;
    const group = groupFor(entries, `game`);
    allow(group);
    group.key = { type: `domain`, domain: group.target, scope: { type: `webBrowsers` } };
    expect(planUnlockReview(entries).problemCount).toBe(1);
    expect(decisionsForSubmission(entries)).toEqual([]);
  });

  test.each([`requestedAddresses`, `perAddress`] as const)(
    `app %s decisions use the same coverage rules`,
    (choice) => {
      const entries = buildUnlockReview([
        request({ id: `source`, ...minecraftApp }),
        request({ id: `target`, domain: `school.example.com`, ...minecraftApp }),
      ]);
      const app = entries[0];
      if (!app || app.kind !== `app`) throw new Error(`Expected app`);
      app.choice = choice;
      allow(groupFor(entries, `source`), `parent`);
      expect(planUnlockReview(entries).decisions).toHaveLength(1);
      expect(planUnlockReview(entries).decidedCount).toBe(2);
    },
  );

  test(`whole-app access ignores dormant address drafts and restores them when turned off`, () => {
    const entries = buildUnlockReview([
      request({ id: `one`, ...minecraftApp }),
      request({ id: `two`, domain: `school.example.com`, ...minecraftApp }),
    ]);
    const app = entries[0];
    if (!app || app.kind !== `app`) throw new Error(`Expected app`);
    const source = groupFor(entries, `one`);
    allow(source, `parent`);
    source.expiration = `2020-01-01T00:00:00Z`;
    groupFor(entries, `two`).decision = `deny`;
    app.choice = `unrestricted`;
    expect(planUnlockReview(entries).problemCount).toBe(0);
    expect(decisionsForSubmission(entries)).toEqual([
      {
        requestIds: [`one`, `two`],
        action: {
          case: `acceptedApp`,
          scope: { type: `identifiedAppSlug`, identifiedAppSlug: `minecraft` },
        },
      },
    ]);
    app.choice = `perAddress`;
    expect(planUnlockReview(entries).problemCount).toBe(1);
    expect(groupFor(entries, `two`).decision).toBe(`deny`);
  });

  test(`deny all rejects every ID without creating the draft permissions`, () => {
    const entries = siblingRequests();
    allow(groupFor(entries, `docs`), `parent`);
    expect(denyAllDecisions(entries)).toEqual([
      { requestIds: [`docs`, `school`], action: { case: `rejected` } },
    ]);
    expect(denyAllDecisions([])).toEqual([]);
    expect(planUnlockReview([])).toMatchObject({
      decisions: [],
      decidedCount: 0,
      problemCount: 0,
    });
  });

  test(`removes credentials, query strings, and fragments from displayed URLs`, () => {
    expect(
      sanitizeRequestedAddress(
        request({
          url: `https://person:secret@school.example.com/lesson/4?token=secret#answers`,
        }),
      ),
    ).toBe(`school.example.com/lesson/4`);
  });
});
