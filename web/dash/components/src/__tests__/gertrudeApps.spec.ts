import { describe, expect, it } from 'vitest';
import { detectClaimPending } from '../gertrudeApps';

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
