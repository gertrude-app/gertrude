import { describe, expect, test } from 'vitest';
import {
  authPageHref,
  authRedirectForPath,
  connectingDeviceFor,
  postAuthLocation,
  validateAuthRedirectSearch,
  validateAuthSearch,
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
      expect(postAuthLocation(path)).toEqual({ to: path });
    }
  });

  test(`preserves search parameters and hashes`, () => {
    const path = `/activity?person=Jude%20Henderson#screenshots` as const;

    expect(authRedirectForPath(path)).toBe(path);
    expect(postAuthLocation(path)).toEqual({ to: path });
  });

  test(`discards external, protocol-relative, and relative destinations`, () => {
    const invalidPaths = [
      `https://example.com/activity`,
      `//example.com/activity`,
      `/\\example.com/activity`,
      `/\t/example.com/activity`,
      [`java`, `script:alert(1)`].join(``),
      `activity`,
      `/login`,
      `/login?redirect=%2Fpeople`,
      ``,
    ];

    for (const path of invalidPaths) {
      expect(authRedirectForPath(path)).toBeUndefined();
      expect(validateAuthRedirectSearch({ redirect: path })).toEqual({});
    }
    expect(validateAuthRedirectSearch({ redirect: 42 })).toEqual({});
    expect(postAuthLocation(undefined)).toEqual({ to: `/people` });
  });

  test(`discards auth pages so logging in never lands on one`, () => {
    const authPaths = [
      `/signout`,
      `/signout/`,
      `/signup?ref=ABC`,
      `/otp/${crypto.randomUUID()}`,
      `/verify-signup-email/${crypto.randomUUID()}`,
      `/reset-password`,
      `/reset-password/${crypto.randomUUID()}`,
      `/link-expired`,
    ];

    for (const path of authPaths) {
      expect(authRedirectForPath(path)).toBeUndefined();
      expect(validateAuthRedirectSearch({ redirect: path })).toEqual({});
    }
    expect(authRedirectForPath(`/signouts`)).toBe(`/signouts`); // prefix match is per segment
  });

  test(`identifies the app being connected from a connect redirect`, () => {
    expect(connectingDeviceFor({ redirect: `/connect/podcasts/123456` })).toEqual({
      app: `podcasts`,
      deviceName: undefined,
    });
    expect(
      connectingDeviceFor({ redirect: `/connect/blockerSupervise/123456` })?.app,
    ).toBe(`blocker`);
    expect(
      connectingDeviceFor({ redirect: `/connect/music/123456`, modelName: `iPad Air` }),
    ).toEqual({ app: `music`, deviceName: `iPad Air` });
    expect(connectingDeviceFor({ redirect: `/people` })).toBeUndefined();
    expect(connectingDeviceFor({ redirect: `/connect/podcasts/12` })).toBeUndefined();
    expect(connectingDeviceFor({})).toBeUndefined();
  });

  test(`carries the device name between login and signup`, () => {
    const search = validateAuthSearch({
      redirect: `/connect/podcasts/123456`,
      modelName: `  iPhone Duo `,
      modelIdentifier: `iPhone19,4`,
    });
    expect(search).toEqual({
      redirect: `/connect/podcasts/123456`,
      modelName: `iPhone Duo`,
      modelIdentifier: `iPhone19,4`,
    });
    expect(authPageHref(`/login`, search)).toBe(
      `/login?redirect=%2Fconnect%2Fpodcasts%2F123456&modelName=iPhone+Duo&modelIdentifier=iPhone19%2C4`,
    );
  });

  test(`drops malformed device params`, () => {
    expect(
      validateAuthSearch({ modelName: `iPhone Duo`, modelIdentifier: `../../etc` }),
    ).toEqual({ modelName: `iPhone Duo` });
    expect(validateAuthSearch({ modelName: 42 })).toEqual({});
  });

  test(`carries referral params and omits empty search`, () => {
    expect(authPageHref(`/signup`, {})).toBe(`/signup`);
    expect(
      authPageHref(`/signup`, validateAuthSearch({ ref: `FRIEND42`, v: `new_site` })),
    ).toBe(`/signup?ref=FRIEND42&v=new_site`);
    expect(validateAuthSearch({ ref: `<script>`, v: `x`.repeat(65) })).toEqual({});
  });
});
