import { describe, expect, test } from 'vitest';
import type { KeychainKey } from '#/components/types';
import { keyPresentation } from '../KeyList';

const record = (key: KeychainKey[`key`], appName?: string): KeychainKey => ({
  id: `key-id`,
  key,
  appName,
});

describe(`keyPresentation`, () => {
  test(`presents every key target type`, () => {
    expect(
      keyPresentation(
        record({
          type: `anySubdomain`,
          domain: `example.com`,
          scope: { type: `webBrowsers` },
        }),
      ).target,
    ).toMatchObject({
      target: `*.example.com`,
      accentPrefix: `*.`,
      kind: `Domain and all subdomains`,
    });
    expect(
      keyPresentation(
        record({
          type: `domain`,
          domain: `api.example.com`,
          scope: { type: `unrestricted` },
        }),
      ).target,
    ).toMatchObject({ target: `api.example.com`, kind: `Specific domain` });
    expect(
      keyPresentation(
        record({
          type: `domainRegex`,
          pattern: `^p\\d+\\.example\\.com$`,
          scope: { type: `webBrowsers` },
        }),
      ).target,
    ).toMatchObject({
      target: `^p\\d+\\.example\\.com$`,
      kind: `Domain pattern`,
      marker: `advanced`,
    });
    expect(
      keyPresentation(
        record({
          type: `ipAddress`,
          ipAddress: `fe80::1%en0`,
          scope: { type: `webBrowsers` },
        }),
      ).target,
    ).toMatchObject({ target: `fe80::1%en0`, kind: `IP address` });
    expect(
      keyPresentation(
        record({
          type: `path`,
          path: `example.com/school`,
          scope: { type: `webBrowsers` },
        }),
      ).target,
    ).toMatchObject({
      target: `example.com/school`,
      kind: `Specific path`,
      marker: `legacy`,
    });
    expect(
      keyPresentation(
        record({
          type: `skeleton`,
          scope: { type: `identifiedAppSlug`, identifiedAppSlug: `spotify` },
        }),
      ).target,
    ).toMatchObject({ target: `Unrestricted internet access`, kind: `App key` });
  });

  test(`presents browser and unrestricted scopes`, () => {
    expect(
      keyPresentation(
        record({
          type: `domain`,
          domain: `example.com`,
          scope: { type: `webBrowsers` },
        }),
      ).scope,
    ).toMatchObject({ label: `Web browsers`, monospace: false });
    expect(
      keyPresentation(
        record({
          type: `domain`,
          domain: `example.com`,
          scope: { type: `unrestricted` },
        }),
      ).scope,
    ).toMatchObject({ label: `All apps`, monospace: false });
  });

  test(`uses friendly app names with raw identifier fallbacks`, () => {
    const identifiedScope = {
      type: `single` as const,
      single: { type: `identifiedAppSlug` as const, identifiedAppSlug: `minecraft` },
    };
    const bundleScope = {
      type: `bundleId` as const,
      bundleId: `com.example.helper`,
    };

    expect(
      keyPresentation(
        record(
          { type: `domain`, domain: `example.com`, scope: identifiedScope },
          `Minecraft`,
        ),
      ).scope,
    ).toMatchObject({ label: `Minecraft`, detail: `Specific app`, monospace: false });
    expect(
      keyPresentation(
        record({ type: `domain`, domain: `example.com`, scope: identifiedScope }),
      ).scope,
    ).toMatchObject({ label: `minecraft`, monospace: true });
    expect(
      keyPresentation(record({ type: `skeleton`, scope: bundleScope })).scope,
    ).toMatchObject({ label: `com.example.helper`, monospace: true });
  });
});
