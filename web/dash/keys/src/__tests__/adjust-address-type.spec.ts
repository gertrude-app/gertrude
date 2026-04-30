import { describe, expect, test } from 'vitest';
import { adjustKeyAddressType, keyForUnlockRequest, originalHost } from '../unlock';

describe(`originalHost()`, () => {
  test(`prefers domain field`, () => {
    expect(
      originalHost({
        url: `https://images.foobar.com/cat.jpg`,
        domain: `images.foobar.com`,
        appCategories: [`browser`],
        appBundleId: `.com.apple.Safari`,
      }),
    ).toBe(`images.foobar.com`);
  });

  test(`falls back to URL host`, () => {
    expect(
      originalHost({
        url: `https://images.foobar.com/cat.jpg`,
        appCategories: [`browser`],
        appBundleId: `.com.apple.Safari`,
      }),
    ).toBe(`images.foobar.com`);
  });

  test(`returns null with neither`, () => {
    expect(
      originalHost({
        ipAddress: `1.2.3.4`,
        appCategories: [`browser`],
        appBundleId: `.com.apple.Safari`,
      }),
    ).toBe(null);
  });
});

describe(`adjustKeyAddressType()`, () => {
  test(`anySubdomain → strict preserves the originally requested subdomain`, () => {
    const request = {
      url: `https://images.foobar.com/cat.jpg`,
      domain: `images.foobar.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    };
    const baseKey = keyForUnlockRequest(request);
    expect(baseKey).toMatchObject({ type: `anySubdomain`, domain: `foobar.com` });

    const adjusted = adjustKeyAddressType(baseKey, `strict`, request);
    expect(adjusted).toMatchObject({
      type: `domain`,
      domain: `images.foobar.com`,
    });
  });

  test(`anySubdomain → strict preserves multi-level subdomain`, () => {
    const request = {
      url: `https://cf.iadsdk.apple.com/adserver/2.6/config`,
      domain: `cf.iadsdk.apple.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    };
    const baseKey = keyForUnlockRequest(request);
    expect(baseKey).toMatchObject({ type: `anySubdomain`, domain: `apple.com` });

    const adjusted = adjustKeyAddressType(baseKey, `strict`, request);
    expect(adjusted).toMatchObject({
      type: `domain`,
      domain: `cf.iadsdk.apple.com`,
    });
  });

  test(`anySubdomain → strict uses URL host when domain field is absent`, () => {
    const request = {
      url: `https://images.foobar.com/cat.jpg`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    };
    const baseKey = keyForUnlockRequest(request);
    expect(baseKey).toMatchObject({ type: `anySubdomain`, domain: `foobar.com` });

    const adjusted = adjustKeyAddressType(baseKey, `strict`, request);
    expect(adjusted).toMatchObject({
      type: `domain`,
      domain: `images.foobar.com`,
    });
  });

  test(`anySubdomain → strict on bare registrable stays as bare registrable`, () => {
    const request = {
      domain: `foobar.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    };
    const baseKey = keyForUnlockRequest(request);
    const adjusted = adjustKeyAddressType(baseKey, `strict`, request);
    expect(adjusted).toMatchObject({ type: `domain`, domain: `foobar.com` });
  });

  test(`domain → standard converts type to anySubdomain (no host change)`, () => {
    const request = {
      domain: `docs.google.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    };
    const baseKey = keyForUnlockRequest(request);
    expect(baseKey).toMatchObject({ type: `domain`, domain: `docs.google.com` });

    const adjusted = adjustKeyAddressType(baseKey, `standard`, request);
    expect(adjusted).toMatchObject({
      type: `anySubdomain`,
      domain: `docs.google.com`,
    });
  });

  test(`returns base key when addressType matches the default`, () => {
    const request = {
      domain: `images.foobar.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    };
    const baseKey = keyForUnlockRequest(request);
    expect(adjustKeyAddressType(baseKey, `standard`, request)).toBe(baseKey);
  });

  test(`returns base key for non-domain key types (ipAddress)`, () => {
    const request = {
      ipAddress: `1.2.3.4`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    };
    const baseKey = keyForUnlockRequest(request);
    expect(baseKey.type).toBe(`ipAddress`);
    expect(adjustKeyAddressType(baseKey, `strict`, request)).toBe(baseKey);
  });

  test(`per-request strict fan-out yields distinct hosts for sibling subdomains`, () => {
    const images = {
      url: `https://images.foobar.com/cat.jpg`,
      domain: `images.foobar.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    };
    const cdn = {
      url: `https://cdn.foobar.com/lib.js`,
      domain: `cdn.foobar.com`,
      appCategories: [`browser`],
      appBundleId: `.com.apple.Safari`,
    };
    const fanOut = [images, cdn].map((req) =>
      adjustKeyAddressType(keyForUnlockRequest(req), `strict`, req),
    );
    expect(fanOut).toEqual([
      {
        type: `domain`,
        domain: `images.foobar.com`,
        scope: { type: `webBrowsers` },
      },
      {
        type: `domain`,
        domain: `cdn.foobar.com`,
        scope: { type: `webBrowsers` },
      },
    ]);
  });
});
