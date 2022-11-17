import { test, describe, expect } from 'vitest';
import type { Key } from '../types';
import { keyForUnlockRequest } from '../unlock';

describe(`keyForUnlockRequest()`, () => {
  test(`dangerous domain set to strict mode`, () => {
    const key = keyForUnlockRequest({
      url: `https://xyz.cloudfront.net/jim/jam.js`,
      appCategories: [`browser`],
      appBundleId: `com.brave`,
      appSlug: `brave`,
    });
    expect(key).toMatchObject({
      type: `domain`, // <-- NOT `anySubdomain`
      domain: `xyz.cloudfront.net`,
      scope: { type: `webBrowsers` },
    });
  });

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
        type: `anySubdomain`,
        domain: `some-site.com`,
        scope: { type: `webBrowsers` },
      },
    ],
    [
      {
        url: `https://docs.google.com/document/d/1/edit`,
        domain: `docs.google.com`,
        ipAddress: `1.2.3.4`,
        appCategories: [`browser`],
        appBundleId: `com.brave`,
        appSlug: `brave`,
      },
      {
        type: `domain`,
        domain: `docs.google.com`,
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
        type: `anySubdomain`,
        domain: `site2.com`,
        scope: { type: `webBrowsers` },
      },
    ],
    [
      {
        url: undefined,
        domain: `www.site3.com`,
        ipAddress: `1.2.3.4`,
        appBundleId: `com.brave`,
        appSlug: `brave`,
        appCategories: [`browser`],
      },
      {
        type: `anySubdomain`,
        domain: `site3.com`,
        scope: { type: `webBrowsers` },
      },
    ],
    [
      {
        url: undefined,
        domain: `static.site4.com`,
        ipAddress: `1.2.3.4`,
        appBundleId: `com.brave`,
        appSlug: `brave`,
        appCategories: [`browser`],
      },
      {
        type: `anySubdomain`,
        domain: `site4.com`,
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
        type: `anySubdomain`,
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
        type: `anySubdomain`,
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
        type: `anySubdomain`,
        domain: `apple.com`,
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
