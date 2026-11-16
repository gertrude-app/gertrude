import { describe, expect, test } from 'vitest';
import type { SharedKey } from '#/components/types';
import type { KeyEditorState } from '../keyEditor';
import {
  broadAccessWarning,
  changeKeyEditorAddress,
  changeKeyEditorDomainMatch,
  changeKeyEditorTargetType,
  domainDetails,
  domainRegexError,
  inferredDomainMatch,
  keyEditorError,
  keyFromEditorState,
  keyToEditorState,
  newKeyEditorState,
} from '../keyEditor';

const state = (overrides: Partial<KeyEditorState> = {}): KeyEditorState => ({
  ...newKeyEditorState(),
  ...overrides,
});

describe(`key editor`, () => {
  test(`infers broad matching for an apex domain`, () => {
    expect(inferredDomainMatch(`example.com`)).toBe(`standard`);
    expect(inferredDomainMatch(`https://example.co.uk/school`)).toBe(`standard`);
  });

  test(`infers exact matching for a hostname with a subdomain`, () => {
    expect(inferredDomainMatch(`foo.example.com`)).toBe(`strict`);
    expect(inferredDomainMatch(`https://school.example.co.uk/path`)).toBe(`strict`);
  });

  test(`extracts the hostname from pasted URLs`, () => {
    expect(domainDetails(`https://Kids.NationalGeographic.com/games?q=animals`)).toEqual({
      hostname: `kids.nationalgeographic.com`,
      hasSubdomain: true,
    });
  });

  test(`resets address and matching when the target type changes`, () => {
    expect(
      changeKeyEditorTargetType(
        state({
          address: `school.example.com`,
          domainMatch: `strict`,
          matchingOverridden: true,
        }),
        `ipAddress`,
      ),
    ).toMatchObject({
      targetType: `ipAddress`,
      address: ``,
      domainMatch: `standard`,
      matchingOverridden: false,
    });
  });

  test(`infers matching until it is manually overridden`, () => {
    const inferred = changeKeyEditorAddress(state(), `school.example.com`);
    expect(inferred.domainMatch).toBe(`strict`);

    const overridden = changeKeyEditorDomainMatch(inferred, `standard`);
    expect(
      changeKeyEditorAddress(overridden, `another.school.example.com`),
    ).toMatchObject({
      domainMatch: `standard`,
      matchingOverridden: true,
    });
  });

  test(`builds broad and exact website keys`, () => {
    expect(
      keyFromEditorState(
        state({
          address: `foo.example.com/path`,
          domainMatch: `standard`,
        }),
      ),
    ).toEqual({
      type: `anySubdomain`,
      domain: `foo.example.com`,
      scope: { type: `webBrowsers` },
    });
    expect(
      keyFromEditorState(
        state({
          address: `foo.example.com/path`,
          domainMatch: `strict`,
        }),
      ),
    ).toEqual({
      type: `domain`,
      domain: `foo.example.com`,
      scope: { type: `webBrowsers` },
    });
  });

  test.each<SharedKey>([
    { type: `anySubdomain`, domain: `mail.google.com`, scope: { type: `webBrowsers` } },
    { type: `anySubdomain`, domain: `www.example.com`, scope: { type: `unrestricted` } },
    { type: `anySubdomain`, domain: `example.co.uk`, scope: { type: `webBrowsers` } },
    { type: `domain`, domain: `docs.example.com`, scope: { type: `webBrowsers` } },
    { type: `ipAddress`, ipAddress: `192.168.1.10`, scope: { type: `webBrowsers` } },
    {
      type: `domainRegex`,
      pattern: `^cdn\\d+\\.example\\.com$`,
      scope: {
        type: `single`,
        single: { type: `bundleId`, bundleId: `com.example.app` },
      },
    },
    {
      type: `domain`,
      domain: `example.com`,
      scope: {
        type: `single`,
        single: { type: `identifiedAppSlug`, identifiedAppSlug: `minecraft` },
      },
    },
  ])(`saves an unedited $type key unchanged`, (key) => {
    const editorState = keyToEditorState({ id: `key-1`, key });
    expect(editorState).not.toBeNull();
    expect(keyFromEditorState({ ...editorState!, comment: `new note` })).toEqual(key);
  });

  test(`builds single-app scopes`, () => {
    expect(
      keyFromEditorState(
        state({
          address: `example.com`,
          scopeType: `singleApp`,
          appSlug: `minecraft`,
        }),
      ),
    ).toMatchObject({
      scope: {
        type: `single`,
        single: { type: `identifiedAppSlug`, identifiedAppSlug: `minecraft` },
      },
    });
    expect(
      keyFromEditorState(
        state({
          address: `example.com`,
          scopeType: `singleApp`,
          appIdentificationType: `bundleId`,
          appBundleId: `com.example.app`,
        }),
      ),
    ).toMatchObject({
      scope: {
        type: `single`,
        single: { type: `bundleId`, bundleId: `com.example.app` },
      },
    });
  });

  test(`accepts home network hostnames`, () => {
    expect(domainDetails(`brw441ca851df82.local`)).toEqual({
      hostname: `brw441ca851df82.local`,
      hasSubdomain: false,
    });
    expect(domainDetails(`http://nas.lan:5000/admin`)).toEqual({
      hostname: `nas.lan`,
      hasSubdomain: false,
    });
    expect(domainDetails(`printer.office.internal`)).toEqual({
      hostname: `printer.office.internal`,
      hasSubdomain: true,
    });
    expect(
      keyFromEditorState(state({ address: `router.home.arpa`, domainMatch: `strict` })),
    ).toEqual({
      type: `domain`,
      domain: `router.home.arpa`,
      scope: { type: `webBrowsers` },
    });
  });

  test(`still rejects malformed and unlisted hostnames`, () => {
    for (const address of [`local`, `-bad.local`, `api.brightspace`, `combfall21.htm`]) {
      expect(keyEditorError(state({ address }))).toContain(`complete website address`);
    }
  });

  test(`suggests the IP address type for IPs entered as websites`, () => {
    for (const address of [`192.168.0.12`, `http://10.0.0.1:8080/`]) {
      expect(keyEditorError(state({ address }))).toContain(
        `Change the type to “IP address”`,
      );
    }
  });

  test(`rejects cloudflare ECH addresses`, () => {
    const editorState = state({ address: `foo.cloudflare-ech.com` });
    expect(keyEditorError(editorState)).toContain(`no key is needed`);
    expect(keyFromEditorState(editorState)).toBeNull();
  });

  test(`uses legacy unsafe domains for broad access warnings`, () => {
    expect(broadAccessWarning(state({ address: `google.com` }))).toContain(
      `every subdomain of google.com`,
    );
    expect(broadAccessWarning(state({ address: `pages.dev` }))).toContain(
      `every subdomain of pages.dev`,
    );
    expect(
      broadAccessWarning(state({ address: `google.com`, domainMatch: `strict` })),
    ).toBeNull();
    expect(broadAccessWarning(state({ address: `discord.com` }))).toBeNull();
    expect(broadAccessWarning(state({ address: `example.com` }))).toBeNull();
  });

  test(`validates domain patterns`, () => {
    expect(domainRegexError(`^.*\\.edu$`)).toBeNull();
    expect(domainRegexError(`(`)).toMatch(/^Enter a valid regular expression \(.+\)\.$/);
    expect(domainRegexError(`.*`)).toContain(`empty hostname`);
    expect(domainRegexError(`.+`)).toContain(`unrelated hostnames`);
  });
});
