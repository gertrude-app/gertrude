import { describe, expect, test } from 'vitest';
import type { AppEntry, UnlockEntry } from '../unlock';
import type { UnlockRequest } from '@dash/types';
import {
  appIdentity,
  groupRequestsByApp,
  groupRequestsByKey,
  keyForUnlockRequest,
  keyIdentity,
  naughtyInfo,
} from '../unlock';

function request(overrides: Partial<UnlockRequest> & { id: string }): UnlockRequest {
  return {
    userId: `user-1`,
    userName: `Test`,
    status: `pending`,
    appCategories: [`browser`],
    appBundleId: `.com.apple.Safari`,
    createdAt: new Date().toISOString() as ISODateString,
    ...overrides,
  };
}

describe(`keyIdentity()`, () => {
  test(`same key produces same identity`, () => {
    const a = keyForUnlockRequest({
      domain: `www.example.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    });
    const b = keyForUnlockRequest({
      domain: `cdn.example.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    });
    expect(keyIdentity(a)).toBe(keyIdentity(b));
  });

  test(`different domains produce different identities`, () => {
    const a = keyForUnlockRequest({
      domain: `example.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    });
    const b = keyForUnlockRequest({
      domain: `other.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    });
    expect(keyIdentity(a)).not.toBe(keyIdentity(b));
  });

  test(`same domain but different app scope produces different identity`, () => {
    const a = keyForUnlockRequest({
      domain: `example.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    });
    const b = keyForUnlockRequest({
      domain: `example.com`,
      appCategories: [],
      appBundleId: `com.some.app`,
    });
    expect(keyIdentity(a)).not.toBe(keyIdentity(b));
  });

  test(`unsafe domain with different subdomains produces different identities`, () => {
    const a = keyForUnlockRequest({
      domain: `docs.google.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    });
    const b = keyForUnlockRequest({
      domain: `mail.google.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    });
    expect(keyIdentity(a)).not.toBe(keyIdentity(b));
  });
});

describe(`groupRequestsByKey()`, () => {
  test(`groups requests producing the same key`, () => {
    const groups = groupRequestsByKey([
      request({ id: `1`, domain: `www.example.com` }),
      request({ id: `2`, domain: `cdn.example.com` }),
      request({ id: `3`, domain: `other.com` }),
    ]);

    expect(groups).toHaveLength(2);
    const exampleGroup = groups.find(
      (g) => g.key.type === `anySubdomain` && g.key.domain === `example.com`,
    );
    expect(exampleGroup).toBeDefined();
    expect(exampleGroup?.allRequests).toHaveLength(2);
    expect(exampleGroup?.duplicateIds).toHaveLength(1);
  });

  test(`single request produces group with no duplicates`, () => {
    const groups = groupRequestsByKey([request({ id: `1`, domain: `example.com` })]);

    expect(groups).toHaveLength(1);
    expect(groups[0]?.duplicateIds).toHaveLength(0);
    expect(groups[0]?.allRequests).toHaveLength(1);
  });

  test(`representative prefers request with comment`, () => {
    const older = new Date(`2024-01-01`).toISOString() as ISODateString;
    const newer = new Date(`2024-06-01`).toISOString() as ISODateString;
    const groups = groupRequestsByKey([
      request({ id: `1`, domain: `example.com`, createdAt: newer }),
      request({
        id: `2`,
        domain: `www.example.com`,
        createdAt: older,
        requestComment: `need this`,
      }),
    ]);

    expect(groups).toHaveLength(1);
    expect(groups[0]?.representative.id).toBe(`2`);
    expect(groups[0]?.duplicateIds).toEqual([`1`]);
  });

  test(`representative picks newest when both have comments`, () => {
    const older = new Date(`2024-01-01`).toISOString() as ISODateString;
    const newer = new Date(`2024-06-01`).toISOString() as ISODateString;
    const groups = groupRequestsByKey([
      request({
        id: `1`,
        domain: `example.com`,
        createdAt: older,
        requestComment: `old`,
      }),
      request({
        id: `2`,
        domain: `www.example.com`,
        createdAt: newer,
        requestComment: `new`,
      }),
    ]);

    expect(groups).toHaveLength(1);
    expect(groups[0]?.representative.id).toBe(`2`);
  });

  test(`does not group requests for unsafe domains with different subdomains`, () => {
    const groups = groupRequestsByKey([
      request({ id: `1`, domain: `docs.google.com` }),
      request({ id: `2`, domain: `mail.google.com` }),
    ]);

    expect(groups).toHaveLength(2);
  });

  test(`groups requests with same URL path but different query strings`, () => {
    const groups = groupRequestsByKey([
      request({ id: `1`, url: `https://example.com/page?q=1`, domain: `example.com` }),
      request({ id: `2`, url: `https://example.com/other?q=2`, domain: `example.com` }),
    ]);

    expect(groups).toHaveLength(1);
    expect(groups[0]?.allRequests).toHaveLength(2);
  });

  test(`preserves all requests in allRequests for merged group`, () => {
    const groups = groupRequestsByKey([
      request({ id: `1`, domain: `a.example.com`, requestComment: `first` }),
      request({ id: `2`, domain: `b.example.com` }),
      request({ id: `3`, domain: `c.example.com`, requestComment: `third` }),
    ]);

    expect(groups).toHaveLength(1);
    expect(groups[0]?.allRequests).toHaveLength(3);
    const ids = groups[0]?.allRequests.map((r) => r.id);
    expect(ids).toContain(`1`);
    expect(ids).toContain(`2`);
    expect(ids).toContain(`3`);
  });
});

describe(`naughtyInfo()`, () => {
  test(`returns deny for google.com subdomain`, () => {
    const result = naughtyInfo(request({ id: `1`, domain: `www.google.com` }));
    expect(result?.level).toBe(`deny`);
  });

  test(`returns deny for youtube.com`, () => {
    const result = naughtyInfo(request({ id: `1`, domain: `www.youtube.com` }));
    expect(result?.level).toBe(`deny`);
  });

  test(`returns deny for chatgpt.com`, () => {
    const result = naughtyInfo(request({ id: `1`, domain: `chatgpt.com` }));
    expect(result?.level).toBe(`deny`);
  });

  test(`returns undefined for safe domain`, () => {
    const result = naughtyInfo(request({ id: `1`, domain: `www.khanacademy.org` }));
    expect(result).toBeUndefined();
  });

  test(`extracts domain from url when no domain field`, () => {
    const result = naughtyInfo(
      request({ id: `1`, url: `https://www.reddit.com/r/homework` }),
    );
    expect(result?.level).toBe(`deny`);
  });

  test(`returns undefined for IP-only request`, () => {
    const result = naughtyInfo(request({ id: `1`, ipAddress: `1.2.3.4` }));
    expect(result).toBeUndefined();
  });

  test(`works with RequestGroup`, () => {
    const groups = groupRequestsByKey([request({ id: `1`, domain: `www.youtube.com` })]);
    const result = naughtyInfo(groups[0]!);
    expect(result?.level).toBe(`deny`);
  });

  test(`returns deny for ad tracking domain`, () => {
    const result = naughtyInfo(
      request({ id: `1`, domain: `googleads.g.doubleclick.net` }),
    );
    expect(result?.level).toBe(`deny`);
  });

  test(`skips deeply nested strict subdomain in group`, () => {
    const groups = groupRequestsByKey([
      request({ id: `1`, domain: `peoplestack-pa.clients6.google.com` }),
    ]);
    expect(naughtyInfo(groups[0]!)).toBeUndefined();
  });

  test(`still flags www.google.com in group (single-level depth)`, () => {
    const groups = groupRequestsByKey([request({ id: `1`, domain: `www.google.com` })]);
    expect(naughtyInfo(groups[0]!)?.level).toBe(`deny`);
  });

  test(`downgrades mail.google.com to undecided in group`, () => {
    const groups = groupRequestsByKey([request({ id: `1`, domain: `mail.google.com` })]);
    expect(naughtyInfo(groups[0]!)?.level).toBe(`undecided`);
    expect(naughtyInfo(groups[0]!)?.reason).toContain(`Related to`);
  });

  test(`downgrades myaccount.google.com to undecided in group`, () => {
    const groups = groupRequestsByKey([
      request({ id: `1`, domain: `myaccount.google.com` }),
    ]);
    expect(naughtyInfo(groups[0]!)?.level).toBe(`undecided`);
  });

  test(`flags copilot.microsoft.com without flagging microsoft.com`, () => {
    const copilot = naughtyInfo(request({ id: `1`, domain: `copilot.microsoft.com` }));
    expect(copilot?.level).toBe(`deny`);
    const office = naughtyInfo(request({ id: `1`, domain: `office.microsoft.com` }));
    expect(office).toBeUndefined();
  });

  test(`hostname-specific entry takes precedence over registrable`, () => {
    const result = naughtyInfo(request({ id: `1`, domain: `copilot.microsoft.com` }));
    expect(result?.reason).toContain(`AI chatbot`);
  });

  test(`flags s3.amazonaws.com (path-style, no region)`, () => {
    const groups = groupRequestsByKey([request({ id: `1`, domain: `s3.amazonaws.com` })]);
    expect(naughtyInfo(groups[0]!)?.level).toBe(`deny`);
  });

  test(`flags s3.us-east-1.amazonaws.com (path-style, regional)`, () => {
    const groups = groupRequestsByKey([
      request({ id: `1`, domain: `s3.us-east-1.amazonaws.com` }),
    ]);
    expect(naughtyInfo(groups[0]!)?.level).toBe(`deny`);
  });

  test(`does not flag virtual-hosted S3 bucket domain`, () => {
    const groups = groupRequestsByKey([
      request({ id: `1`, domain: `my-bucket.s3.amazonaws.com` }),
    ]);
    expect(naughtyInfo(groups[0]!)).toBeUndefined();
  });

  test(`flags storage.googleapis.com`, () => {
    const result = naughtyInfo(request({ id: `1`, domain: `storage.googleapis.com` }));
    expect(result?.level).toBe(`deny`);
  });

  test(`still flags doubleclick subdomain in group (anySubdomain key)`, () => {
    const groups = groupRequestsByKey([
      request({ id: `1`, domain: `googleads.g.doubleclick.net` }),
    ]);
    expect(naughtyInfo(groups[0]!)?.level).toBe(`deny`);
  });
});

function appEntry(entry: UnlockEntry | undefined): AppEntry {
  expect(entry?.kind).toBe(`app`);
  return entry as AppEntry;
}

describe(`appIdentity()`, () => {
  test(`returns null for webBrowsers scope`, () => {
    const key = keyForUnlockRequest({
      domain: `example.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    });
    expect(appIdentity(key)).toBeNull();
  });

  test(`returns slug identity for identifiedAppSlug scope`, () => {
    const key = keyForUnlockRequest({
      domain: `unity.com`,
      appCategories: [],
      appSlug: `unity-hub`,
    });
    expect(appIdentity(key)).toEqual({ id: `slug:unity-hub`, slug: `unity-hub` });
  });

  test(`returns bundle identity for bundleId scope`, () => {
    const key = keyForUnlockRequest({
      domain: `unity.com`,
      appCategories: [],
      appBundleId: `com.unity.hub`,
    });
    expect(appIdentity(key)).toEqual({
      id: `bundle:com.unity.hub`,
      bundleId: `com.unity.hub`,
    });
  });
});

describe(`groupRequestsByApp()`, () => {
  test(`browser requests stay as 1:1 web entries`, () => {
    const entries = groupRequestsByApp([
      request({ id: `1`, domain: `khanacademy.org` }),
      request({ id: `2`, domain: `wikipedia.org` }),
    ]);

    expect(entries).toHaveLength(2);
    expect(entries.every((e) => e.kind === `web`)).toBe(true);
  });

  test(`collapses one app's many hosts into a single app super-group`, () => {
    const entries = groupRequestsByApp([
      request({
        id: `1`,
        domain: `docs.unity.com`,
        appCategories: [],
        appSlug: `unity-hub`,
      }),
      request({
        id: `2`,
        domain: `assets.unity3d.com`,
        appCategories: [],
        appSlug: `unity-hub`,
      }),
      request({
        id: `3`,
        domain: `cdn.cloudunity.net`,
        appCategories: [],
        appSlug: `unity-hub`,
      }),
    ]);

    expect(entries).toHaveLength(1); // whack-a-mole collapsed
    const app = appEntry(entries[0]);
    expect(app.id).toBe(`app:slug:unity-hub`);
    expect(app.hostGroups).toHaveLength(3); // one per distinct host
  });

  test(`different apps produce different app entries`, () => {
    const entries = groupRequestsByApp([
      request({ id: `1`, domain: `unity.com`, appCategories: [], appSlug: `unity-hub` }),
      request({
        id: `2`,
        domain: `minecraft.net`,
        appCategories: [],
        appSlug: `minecraft`,
      }),
    ]);

    expect(entries).toHaveLength(2);
    expect(entries.map((e) => e.id)).toEqual([
      `app:slug:unity-hub`,
      `app:slug:minecraft`,
    ]);
  });

  test(`slug identity collapses across differing bundle ids`, () => {
    const entries = groupRequestsByApp([
      request({
        id: `1`,
        domain: `unity.com`,
        appCategories: [],
        appSlug: `unity-hub`,
        appBundleId: `com.unity.hub`,
      }),
      request({
        id: `2`,
        domain: `unity3d.com`,
        appCategories: [],
        appSlug: `unity-hub`,
        appBundleId: `TEAMID.com.unity.hub`,
      }),
    ]);

    expect(entries).toHaveLength(1); // slug wins over bundle-variant
    expect(appEntry(entries[0]).hostGroups).toHaveLength(2); // two distinct hosts, one app
  });

  test(`groups by bundleId when no slug is present`, () => {
    const entries = groupRequestsByApp([
      request({
        id: `1`,
        domain: `a.example.com`,
        appCategories: [],
        appBundleId: `com.some.app`,
      }),
      request({
        id: `2`,
        domain: `b.example.com`,
        appCategories: [],
        appBundleId: `com.some.app`,
      }),
    ]);

    expect(entries).toHaveLength(1);
    expect(appEntry(entries[0]).id).toBe(`app:bundle:com.some.app`);
  });

  test(`preserves first-seen order across mixed web and app entries`, () => {
    const entries = groupRequestsByApp([
      request({ id: `1`, domain: `khanacademy.org` }), // web
      request({
        id: `2`,
        domain: `docs.unity.com`,
        appCategories: [],
        appSlug: `unity-hub`,
      }), // app
      request({ id: `3`, domain: `wikipedia.org` }), // web
      request({
        id: `4`,
        domain: `assets.unity3d.com`,
        appCategories: [],
        appSlug: `unity-hub`,
      }), // same app
    ]);

    expect(entries.map((e) => e.kind)).toEqual([`web`, `app`, `web`]); // unity folds into entry #2
    expect(appEntry(entries[1]).hostGroups).toHaveLength(2);
  });

  test(`app entry carries name, slug, bundleId, and icon hash from representative`, () => {
    const entries = groupRequestsByApp([
      request({
        id: `1`,
        domain: `unity.com`,
        appCategories: [],
        appSlug: `unity-hub`,
        appBundleId: `com.unity.hub`,
        appName: `Unity Hub`,
        appIconHash: `abc123`,
      }),
    ]);

    const app = appEntry(entries[0]);
    expect(app.appName).toBe(`Unity Hub`);
    expect(app.appSlug).toBe(`unity-hub`);
    expect(app.appBundleId).toBe(`com.unity.hub`);
    expect(app.appIconHash).toBe(`abc123`);
  });

  test(`app super-group host groups keep their merged duplicates`, () => {
    const entries = groupRequestsByApp([
      request({
        id: `1`,
        domain: `docs.unity.com`,
        appCategories: [],
        appSlug: `unity-hub`,
      }),
      request({
        id: `2`,
        domain: `docs.unity.com`,
        appCategories: [],
        appSlug: `unity-hub`,
      }),
    ]);

    const app = appEntry(entries[0]);
    expect(app.hostGroups).toHaveLength(1); // same host merges to one host group
    expect(app.hostGroups[0]?.allRequests).toHaveLength(2);
  });
});
