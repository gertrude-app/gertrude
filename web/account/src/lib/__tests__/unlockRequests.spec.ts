import { describe, expect, test } from 'vitest';
import type { GetPersonUnlockRequests } from '@shared/pairql/src/account';
import {
  buildUnlockReview,
  decidedRequestCount,
  decisionsForSubmission,
  keyForUnlockRequest,
  sanitizeRequestedAddress,
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

describe(`unlock request review`, () => {
  test(`groups browser requests that produce the same least-privilege key`, () => {
    const entries = buildUnlockReview([
      request({ id: `one`, domain: `docs.example.com` }),
      request({ id: `two`, domain: `school.example.com` }),
    ]);

    expect(entries).toHaveLength(1);
    expect(entries[0]).toMatchObject({
      kind: `web`,
      group: {
        requestIds: [`one`, `two`],
        target: `example.com`,
        key: { type: `anySubdomain`, domain: `example.com` },
        decision: `undecided`,
      },
    });
  });

  test(`keeps technically broad services on exact hosts`, () => {
    expect(
      keyForUnlockRequest(request({ domain: `classroom.google.com` })),
    ).toMatchObject({
      type: `domain`,
      domain: `classroom.google.com`,
    });
  });

  test(`strong service warnings default to deny while cautions stay undecided`, () => {
    const entries = buildUnlockReview([
      request({ id: `youtube`, domain: `youtube.com` }),
      request({ id: `classroom`, domain: `classroom.google.com` }),
      request({ id: `medium`, domain: `medium.com` }),
      request({ id: `ip`, domain: undefined, ipAddress: `192.0.2.1` }),
    ]);
    const groups = entries.flatMap((entry) =>
      entry.kind === `web` ? [entry.group] : entry.groups,
    );

    expect(groups.find((group) => group.requestIds.includes(`youtube`))).toMatchObject({
      decision: `deny`,
      risk: { level: `strongWarning` },
    });
    expect(groups.find((group) => group.requestIds.includes(`classroom`))).toMatchObject({
      decision: `undecided`,
      risk: { level: `caution`, reason: `This address is related to google.com.` },
    });
    expect(groups.find((group) => group.requestIds.includes(`medium`))).toMatchObject({
      decision: `undecided`,
      risk: { level: `caution` },
    });
    expect(groups.find((group) => group.requestIds.includes(`ip`))).toMatchObject({
      decision: `undecided`,
      risk: { level: `caution` },
    });
    expect(decidedRequestCount(entries)).toBe(1);
  });

  test(`starts a mixed-risk app in per-address mode`, () => {
    const appRequest = {
      appName: `Discord`,
      appSlug: `discord`,
      appBundleId: `com.discord.Discord`,
      appCategories: [`communication`],
    };
    const entries = buildUnlockReview([
      request({ id: `risky`, domain: `discord.com`, ...appRequest }),
      request({ id: `ordinary`, domain: `status.example.com`, ...appRequest }),
    ]);

    expect(entries).toHaveLength(1);
    expect(entries[0]).toMatchObject({
      kind: `app`,
      name: `Discord`,
      choice: `perAddress`,
      groups: [
        { decision: `deny`, risk: { level: `strongWarning` } },
        { decision: `undecided` },
      ],
    });
    expect(decidedRequestCount(entries)).toBe(1);
  });

  test(`submits grouped IDs once and allows requested app addresses with keys`, () => {
    const appRequest = {
      appName: `Minecraft`,
      appSlug: `minecraft`,
      appBundleId: `com.mojang.minecraft`,
      appCategories: [`game`],
    };
    const entries = buildUnlockReview(
      [
        request({ id: `one`, domain: `api.example.com`, ...appRequest }),
        request({ id: `two`, domain: `cdn.example.com`, ...appRequest }),
      ],
      `keychain-id`,
    );
    const app = entries[0];
    if (!app || app.kind !== `app`) {
      throw new Error(`Expected app entry`);
    }
    app.choice = `requestedAddresses`;

    expect(decisionsForSubmission(entries)).toEqual([
      {
        requestIds: [`one`, `two`],
        action: {
          case: `acceptedKey`,
          keychainId: `keychain-id`,
          key: {
            type: `anySubdomain`,
            domain: `example.com`,
            scope: {
              type: `single`,
              single: {
                type: `identifiedAppSlug`,
                identifiedAppSlug: `minecraft`,
              },
            },
          },
          comment: undefined,
          expiration: undefined,
        },
      },
    ]);
  });

  test(`unrestricted app access resolves every address with one explicit app action`, () => {
    const entries = buildUnlockReview([
      request({
        id: `one`,
        domain: `one.example`,
        appName: undefined,
        appSlug: undefined,
        appBundleId: `com.example.unknown`,
        appCategories: [`other`],
      }),
      request({
        id: `two`,
        domain: `two.example`,
        appName: undefined,
        appSlug: undefined,
        appBundleId: `com.example.unknown`,
        appCategories: [`other`],
      }),
    ]);
    const app = entries[0];
    if (!app || app.kind !== `app`) {
      throw new Error(`Expected app entry`);
    }
    app.choice = `unrestricted`;

    expect(decisionsForSubmission(entries)).toEqual([
      {
        requestIds: [`one`, `two`],
        action: {
          case: `acceptedApp`,
          scope: { type: `bundleId`, bundleId: `com.example.unknown` },
        },
      },
    ]);
  });

  test(`lets a parent override smart matching without changing key scope`, () => {
    const entry = buildUnlockReview([request({ domain: `docs.example.com` })])[0];
    if (!entry || entry.kind !== `web`) {
      throw new Error(`Expected web entry`);
    }

    const strict = updateGroupKeyAddressMatch(entry.group, false);
    const broad = updateGroupKeyAddressMatch(strict, true);

    expect(strict.key).toMatchObject({
      type: `domain`,
      domain: `docs.example.com`,
      scope: { type: `webBrowsers` },
    });
    expect(broad.key).toMatchObject({
      type: `anySubdomain`,
      domain: `example.com`,
      scope: { type: `webBrowsers` },
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
