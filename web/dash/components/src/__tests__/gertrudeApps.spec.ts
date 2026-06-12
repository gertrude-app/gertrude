import { describe, expect, it } from 'vitest';
import { detectClaimFunnelPath, detectClaimPending } from '../gertrudeApps';

describe(`detectClaimPending()`, () => {
  it(`maps claimPendingAmDevice to the podcasts app`, () => {
    const params = new URLSearchParams(`claimPendingAmDevice=778899`);
    expect(detectClaimPending(params)).toEqual({ app: `podcasts`, claimCode: `778899` });
  });

  it(`maps claimPendingSupervision to the blocker app`, () => {
    const params = new URLSearchParams(`claimPendingSupervision=123456`);
    expect(detectClaimPending(params)).toEqual({ app: `blocker`, claimCode: `123456` });
  });

  it(`returns null when no claim param is present`, () => {
    expect(detectClaimPending(new URLSearchParams(`modelName=iPhone+15+Pro`))).toBeNull();
  });

  it(`ignores an empty claim param value`, () => {
    expect(detectClaimPending(new URLSearchParams(`claimPendingAmDevice=`))).toBeNull();
  });
});

describe(`detectClaimFunnelPath()`, () => {
  it(`maps a claim-am-device path to the podcasts app`, () => {
    expect(detectClaimFunnelPath(`/claim-am-device/778899/claim`)).toEqual({
      app: `podcasts`,
      claimCode: `778899`,
    });
  });

  it(`maps a supervise-device path to the blocker app`, () => {
    expect(detectClaimFunnelPath(`/supervise-device/123456/claim`)).toEqual({
      app: `blocker`,
      claimCode: `123456`,
    });
  });

  it(`matches funnel subroutes`, () => {
    expect(detectClaimFunnelPath(`/supervise-device/123456/payment`)).toEqual({
      app: `blocker`,
      claimCode: `123456`,
    });
    expect(detectClaimFunnelPath(`/claim-am-device/778899/done`)).toEqual({
      app: `podcasts`,
      claimCode: `778899`,
    });
  });

  it(`matches a bare funnel path with no subroute`, () => {
    expect(detectClaimFunnelPath(`/supervise-device/123456`)).toEqual({
      app: `blocker`,
      claimCode: `123456`,
    });
  });

  it(`returns null for non-funnel paths`, () => {
    expect(detectClaimFunnelPath(`/`)).toBeNull();
    expect(detectClaimFunnelPath(`/children`)).toBeNull();
    expect(detectClaimFunnelPath(`/children/123/ios-devices/456`)).toBeNull();
  });

  it(`returns null for a non-numeric claim code`, () => {
    expect(detectClaimFunnelPath(`/claim-am-device/abc123/claim`)).toBeNull();
  });

  it(`returns null when the funnel segment is not at the path root`, () => {
    expect(detectClaimFunnelPath(`/foo/claim-am-device/778899/claim`)).toBeNull();
  });
});
