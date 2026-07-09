import { describe, expect, it } from 'vitest';
import {
  claimFunnelPath,
  detectClaimFunnelPath,
  detectClaimPending,
} from '../gertrudeApps';

describe(`detectClaimPending()`, () => {
  it(`maps claimPendingPodcastsDevice to the podcasts intent`, () => {
    const params = new URLSearchParams(`claimPendingPodcastsDevice=778899`);
    expect(detectClaimPending(params)).toEqual({
      intent: `podcasts`,
      claimCode: `778899`,
    });
  });

  it(`maps claimPendingSupervision to the blockerSupervise intent`, () => {
    const params = new URLSearchParams(`claimPendingSupervision=123456`);
    expect(detectClaimPending(params)).toEqual({
      intent: `blockerSupervise`,
      claimCode: `123456`,
    });
  });

  it(`maps claimPendingBlocker to the blockerConnect intent`, () => {
    const params = new URLSearchParams(`claimPendingBlocker=123456`);
    expect(detectClaimPending(params)).toEqual({
      intent: `blockerConnect`,
      claimCode: `123456`,
    });
  });

  it(`returns null when no claim param is present`, () => {
    expect(detectClaimPending(new URLSearchParams(`modelName=iPhone+15+Pro`))).toBeNull();
  });

  it(`ignores an empty claim param value`, () => {
    expect(
      detectClaimPending(new URLSearchParams(`claimPendingPodcastsDevice=`)),
    ).toBeNull();
  });
});

describe(`claimFunnelPath()`, () => {
  it(`builds the podcasts funnel path for the podcasts intent`, () => {
    expect(claimFunnelPath(`podcasts`, `778899`)).toBe(
      `/claim-podcasts-device/778899/claim`,
    );
  });

  it(`builds the supervision funnel path for the blockerSupervise intent`, () => {
    expect(claimFunnelPath(`blockerSupervise`, `123456`)).toBe(
      `/supervise-device/123456/claim`,
    );
  });

  it(`builds the connect funnel path for the blockerConnect intent`, () => {
    expect(claimFunnelPath(`blockerConnect`, `123456`)).toBe(
      `/claim-blocker-device/123456/claim`,
    );
  });

  it(`round-trips with detectClaimFunnelPath`, () => {
    expect(detectClaimFunnelPath(claimFunnelPath(`podcasts`, `778899`))).toEqual({
      intent: `podcasts`,
      claimCode: `778899`,
    });
  });
});

describe(`detectClaimFunnelPath()`, () => {
  it(`maps a claim-podcasts-device path to the podcasts intent`, () => {
    expect(detectClaimFunnelPath(`/claim-podcasts-device/778899/claim`)).toEqual({
      intent: `podcasts`,
      claimCode: `778899`,
    });
  });

  it(`maps a supervise-device path to the blockerSupervise intent`, () => {
    expect(detectClaimFunnelPath(`/supervise-device/123456/claim`)).toEqual({
      intent: `blockerSupervise`,
      claimCode: `123456`,
    });
  });

  it(`maps a claim-blocker-device path to the blockerConnect intent`, () => {
    expect(detectClaimFunnelPath(`/claim-blocker-device/123456/claim`)).toEqual({
      intent: `blockerConnect`,
      claimCode: `123456`,
    });
  });

  it(`matches funnel subroutes`, () => {
    expect(detectClaimFunnelPath(`/supervise-device/123456/payment`)).toEqual({
      intent: `blockerSupervise`,
      claimCode: `123456`,
    });
    expect(detectClaimFunnelPath(`/claim-podcasts-device/778899/done`)).toEqual({
      intent: `podcasts`,
      claimCode: `778899`,
    });
  });

  it(`matches a bare funnel path with no subroute`, () => {
    expect(detectClaimFunnelPath(`/supervise-device/123456`)).toEqual({
      intent: `blockerSupervise`,
      claimCode: `123456`,
    });
  });

  it(`returns null for non-funnel paths`, () => {
    expect(detectClaimFunnelPath(`/`)).toBeNull();
    expect(detectClaimFunnelPath(`/children`)).toBeNull();
    expect(detectClaimFunnelPath(`/children/123/ios-devices/456`)).toBeNull();
  });

  it(`returns null for a non-numeric claim code`, () => {
    expect(detectClaimFunnelPath(`/claim-podcasts-device/abc123/claim`)).toBeNull();
  });

  it(`returns null when the funnel segment is not at the path root`, () => {
    expect(detectClaimFunnelPath(`/foo/claim-podcasts-device/778899/claim`)).toBeNull();
  });
});
