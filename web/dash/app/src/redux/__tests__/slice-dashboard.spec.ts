import { expect, test, describe } from 'vitest';
import { Req } from '../helpers';
import reducer from '../slice-dashboard';
import { acceptUnlockRequest, rejectUnlockRequest } from '../slice-unlock-requests';
import { makeState } from './test-helpers';

describe(`reducer`, () => {
  test(`deciding unlock request removes it from dashboard`, () => {
    const state = makeState();
    state.dashboard.request = {
      state: `succeeded`,
      payload: {
        unlockRequests: [
          {
            id: `request-123`,
            target: `happyfish.com`,
            userId: `2`,
            userName: `Huck`,
            createdAt: ``,
          },
        ],
        users: [],
        userActivitySummaries: [],
        recentScreenshots: [],
      },
    };

    let next = reducer(
      state.dashboard,
      acceptUnlockRequest.succeeded({ success: true }, `request-123`),
    );
    expect(Req.payload(next.request)?.unlockRequests).toEqual([]);

    next = reducer(
      state.dashboard,
      rejectUnlockRequest.succeeded({ success: true }, `request-123`),
    );
    expect(Req.payload(next.request)?.unlockRequests).toEqual([]);
  });
});
