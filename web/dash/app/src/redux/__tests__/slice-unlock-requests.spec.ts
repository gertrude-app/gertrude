import { expect, test, describe } from 'vitest';
import reducer, {
  acceptUnlockRequest,
  rejectUnlockRequest,
} from '../slice-unlock-requests';
import { makeState } from './test-helpers';

describe(`reducer`, () => {
  test(`ephemeral state is cleared when unlock request accepted`, () => {
    const state = makeState((s) => {
      s.unlockRequests.detailsExpanded = true;
      s.unlockRequests.selectedKeychainId = `1`;
    });
    const nextState = reducer(
      state.unlockRequests,
      acceptUnlockRequest.succeeded(true, `1`),
    );
    expect(nextState.selectedKeychainId).toBe(undefined);
    expect(nextState.detailsExpanded).toBe(false);
  });

  test(`ephemeral state is cleared when unlock request rejected`, () => {
    const state = makeState((s) => {
      s.unlockRequests.detailsExpanded = true;
      s.unlockRequests.selectedKeychainId = `1`;
      s.unlockRequests.denyComment = `nope`;
    });
    const nextState = reducer(
      state.unlockRequests,
      rejectUnlockRequest.succeeded(true, `1`),
    );
    expect(nextState.selectedKeychainId).toBe(undefined);
    expect(nextState.detailsExpanded).toBe(false);
    expect(nextState.denyComment).toBe(undefined);
  });
});
