import { describe, expect, test } from 'vitest';
import {
  authRedirectForPath,
  postAuthLocation,
  validateAuthRedirectSearch,
} from '../authRedirect';

describe(`Account auth redirects`, () => {
  test(`preserves any local Account path`, () => {
    const paths = [
      `/requests/suspension/${crypto.randomUUID()}`,
      `/activity/person/${crypto.randomUUID()}/day/2026-07-24`,
      `/a-page-that-does-not-exist`,
    ] as const;

    for (const path of paths) {
      expect(authRedirectForPath(path)).toBe(path);
      expect(validateAuthRedirectSearch({ redirect: path })).toEqual({ redirect: path });
      expect(postAuthLocation(path)).toEqual({ href: path });
    }
  });

  test(`preserves search parameters and hashes`, () => {
    const path = `/activity?person=Jude%20Henderson#screenshots` as const;

    expect(authRedirectForPath(path)).toBe(path);
    expect(postAuthLocation(path)).toEqual({ href: path });
  });

  test(`discards external, protocol-relative, and relative destinations`, () => {
    const invalidPaths = [
      `https://example.com/activity`,
      `//example.com/activity`,
      `/\\example.com/activity`,
      `/\t/example.com/activity`,
      [`java`, `script:alert(1)`].join(``),
      `activity`,
      ``,
    ];

    for (const path of invalidPaths) {
      expect(authRedirectForPath(path)).toBeUndefined();
      expect(validateAuthRedirectSearch({ redirect: path })).toEqual({});
    }
    expect(validateAuthRedirectSearch({ redirect: 42 })).toEqual({});
    expect(postAuthLocation(undefined)).toEqual({ href: `/people` });
  });
});
