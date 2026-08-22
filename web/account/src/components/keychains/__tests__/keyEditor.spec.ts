import { describe, expect, test } from 'vitest';
import type { KeyEditorState } from '../keyEditor';
import {
  broadAccessWarning,
  domainDetails,
  domainRegexError,
  inferredDomainMatch,
  keyEditorError,
  keyFromEditorState,
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

  test(`extracts the hostname and registrable domain from pasted URLs`, () => {
    expect(domainDetails(`https://Kids.NationalGeographic.com/games?q=animals`)).toEqual({
      hostname: `kids.nationalgeographic.com`,
      registrableDomain: `nationalgeographic.com`,
      hasSubdomain: true,
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
      domain: `example.com`,
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

  test(`rejects cloudflare ECH addresses`, () => {
    const editorState = state({ address: `foo.cloudflare-ech.com` });
    expect(keyEditorError(editorState)).toContain(`no key is needed`);
    expect(keyFromEditorState(editorState)).toBeNull();
  });

  test(`warns about subdomain access for known broad domains`, () => {
    expect(broadAccessWarning(state({ address: `google.com` }))).toContain(
      `every subdomain of google.com`,
    );
    expect(
      broadAccessWarning(state({ address: `google.com`, domainMatch: `strict` })),
    ).toBeNull();
    expect(broadAccessWarning(state({ address: `example.com` }))).toBeNull();
  });

  test(`validates domain patterns`, () => {
    expect(domainRegexError(`^.*\\.edu$`)).toBeNull();
    expect(domainRegexError(`(`)).toContain(`valid regular expression`);
    expect(domainRegexError(`.*`)).toContain(`empty hostname`);
    expect(domainRegexError(`.+`)).toContain(`unrelated hostnames`);
  });
});
