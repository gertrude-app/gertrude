import { describe, expect, test } from 'vitest';
import { matchingTabHref } from '../SegmentedTabLinks';

const personTabs = [`/people/1`, `/people/1/mac-settings`, `/people/1/ios-settings`];

describe(`matchingTabHref`, () => {
  test(`exact match`, () => {
    expect(matchingTabHref(personTabs, `/people/1/ios-settings`)).toBe(
      `/people/1/ios-settings`,
    );
  });

  test(`nested route still selects its tab`, () => {
    // regression: /ios-settings/<deviceId> used to select nothing
    expect(matchingTabHref(personTabs, `/people/1/ios-settings/abc-123`)).toBe(
      `/people/1/ios-settings`,
    );
  });

  test(`longest match wins over the parent tab`, () => {
    // `/people/1` is also a prefix, but must not win
    expect(matchingTabHref(personTabs, `/people/1/mac-settings`)).toBe(
      `/people/1/mac-settings`,
    );
  });

  test(`parent tab selected at its own path`, () => {
    expect(matchingTabHref(personTabs, `/people/1`)).toBe(`/people/1`);
  });

  test(`trailing slashes normalized`, () => {
    expect(matchingTabHref(personTabs, `/people/1/ios-settings/`)).toBe(
      `/people/1/ios-settings`,
    );
  });

  test(`a sibling with a shared prefix does not match`, () => {
    expect(
      matchingTabHref([`/requests/unlock`], `/requests/unlock-archive`),
    ).toBeUndefined();
  });

  test(`no match returns undefined`, () => {
    expect(matchingTabHref(personTabs, `/settings/notifications`)).toBeUndefined();
  });
});
