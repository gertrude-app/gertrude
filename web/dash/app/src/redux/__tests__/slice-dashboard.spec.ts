import { expect, test, describe } from 'vitest';
import { Req } from '../helpers';
import reducer from '../slice-dashboard';
import { acceptUnlockRequest, rejectUnlockRequest } from '../slice-unlock-requests';
import { deleteActivityItems } from '../slice-users';
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

  test(`approving activity items removes them from dashboard widget`, () => {
    const state = makeState();
    state.dashboard.request = {
      state: `succeeded`,
      payload: {
        unlockRequests: [],
        users: [],
        userActivitySummaries: [
          // i added the `numReviewd` and made them up
          { id: `2`, name: `Huck`, numReviewed: 22, numUnreviewed: 11 },
          { id: `3`, name: `Bob`, numReviewed: 33, numUnreviewed: 33 },
        ],
        recentScreenshots: [],
      },
    };

    const next = reducer(
      state.dashboard,
      deleteActivityItems.succeeded(
        { success: true },
        {
          userId: `2`,
          itemRootIds: [`1`, `2`],
          date: new Date(),
        },
      ),
    );
    expect(Req.payload(next.request)?.userActivitySummaries).toEqual([
      { id: `2`, name: `Huck`, numReviewed: 22, numUnreviewed: 9 },
      { id: `3`, name: `Bob`, numReviewed: 33, numUnreviewed: 33 },
    ]);
  });

  test(`approving activity items never results in negative numbers`, () => {
    const state = makeState();
    state.dashboard.request = {
      state: `succeeded`,
      payload: {
        unlockRequests: [],
        users: [],
        userActivitySummaries: [
          { id: `2`, name: `Huck`, numReviewed: 1, numUnreviewed: 1 },
        ],
        recentScreenshots: [],
      },
    };

    const next = reducer(
      state.dashboard,
      deleteActivityItems.succeeded(
        { success: true },
        {
          userId: `2`,
          // more than the number of unreviewed items, some came in since load
          itemRootIds: [`1`, `2`],
          date: new Date(),
        },
      ),
    );
    expect(Req.payload(next.request)?.userActivitySummaries).toEqual([
      { id: `2`, name: `Huck`, numReviewed: 1, numUnreviewed: 0 },
    ]);
  });
});
