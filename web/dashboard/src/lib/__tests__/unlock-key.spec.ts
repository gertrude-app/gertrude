import { test, describe, expect } from 'vitest';
import { keyForUnlockRequest } from '../unlock-key';

describe(`keyForUnlockRequest()`, () => {
  const cases: Array<[Parameters<typeof keyForUnlockRequest>[0], Key]> = [
    [
      {
        url: `https://some-site.com/jim/jam`,
        domain: `some-site.com`,
        ipAddress: `1.2.3.4`,
        appCategories: [`browser`],
        appBundleId: `com.brave`,
        appSlug: `brave`,
      },
      {
        type: `domain`,
        domain: `some-site.com`,
        scope: { type: `webBrowsers` },
      },
    ],
    [
      {
        url: undefined,
        domain: `site2.com`,
        ipAddress: `1.2.3.4`,
        appBundleId: `com.brave`,
        appSlug: `brave`,
        appCategories: [`browser`],
      },
      {
        type: `domain`,
        domain: `site2.com`,
        scope: { type: `webBrowsers` },
      },
    ],
    [
      {
        url: undefined,
        domain: undefined,
        ipAddress: `1.2.3.4`,
        appBundleId: `com.brave`,
        appSlug: `brave`,
        appCategories: [`browser`],
      },
      {
        type: `ipAddress`,
        ipAddress: `1.2.3.4`,
        scope: { type: `webBrowsers` },
      },
    ],
    [
      {
        url: undefined,
        domain: `school-site.com`,
        ipAddress: `1.2.3.4`,
        appBundleId: `com.widget`,
        appSlug: `widget`,
        appCategories: [],
      },
      {
        type: `domain`,
        domain: `school-site.com`,
        scope: {
          type: `single`,
          single: { type: `identifiedAppSlug`, identifiedAppSlug: `widget` },
        },
      },
    ],
    [
      {
        url: undefined,
        domain: `school-site2.com`,
        ipAddress: `1.2.3.4`,
        appBundleId: `com.unknown`,
        appSlug: undefined,
        appCategories: [],
      },
      {
        type: `domain`,
        domain: `school-site2.com`,
        scope: {
          type: `single`,
          single: { type: `bundleId`, bundleId: `com.unknown` },
        },
      },
    ],
    [
      {
        url: `https://cf.iadsdk.apple.com/adserver/2.6/config`,
        domain: `cf.iadsdk.apple.com`,
        ipAddress: `0.0.0.0`,
        appBundleId: `.com.apple.ap.adprivacyd`,
        appCategories: [],
      },
      {
        type: `domain`,
        domain: `cf.iadsdk.apple.com`,
        scope: {
          type: `single`,
          single: {
            type: `bundleId`,
            bundleId: `.com.apple.ap.adprivacyd`,
          },
        },
      },
    ],
  ];

  test.each(cases)(`unlock request -> create key`, (decision, expectedKey) => {
    expect(keyForUnlockRequest(decision)).toMatchObject(expectedKey);
  });
});
