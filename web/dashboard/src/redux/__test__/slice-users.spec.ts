import { expect, it, describe, vi } from 'vitest';
import { GetActivityOverview_counts } from '../../api/users/__generated__/GetActivityOverview';
import { ActivityItem } from '@shared/dashboard/Users/Activity/ReviewDay';
import { Req } from '../helpers';
import Current from '../../environment';
import { State } from '../store';
import reducer, {
  activityItemsDeleted,
  deleteActivityItems,
  initialState,
  fetchActivityOverview,
} from '../slice-users';

describe(`fetchActivityOverview`, () => {
  it(`filters out ranges with no items, and orders most recent first`, async () => {
    let state = reducer(void 0, fetchActivityOverview.started({ userId: `user123` }));
    expect(state.activityOverviews).toEqual({ user123: Req.ongoing() });

    state = reducer(
      state,
      fetchActivityOverview.succeeded(
        {
          user: { __typename: `User`, name: `Huck` },
          counts: [
            overviewCount(5, 0, `01-01-2022`),
            overviewCount(0, 0, `01-03-2022`), // <-- should be filtered out
            overviewCount(11, 0, `01-05-2022`), // <-- most recent, should be first
          ],
        },
        { userId: `user123` },
      ),
    );

    expect(state.activityOverviews).toEqual({
      user123: Req.succeed({
        user: { __typename: `User`, name: `Huck` },
        counts: [
          overviewCount(11, 0, `01-05-2022`), // <-- most recent
          overviewCount(5, 0, `01-01-2022`),
        ],
      }),
    });
  });
});

describe(`deleteActivityItems`, () => {
  it(`dispatches correct action and invokes api`, () => {
    const users = {
      ...initialState,
      activityDays: {
        'user123--01-01-2022': Req.succeed({
          numDeleted: 0,
          items: {
            item1: keystrokeLine(`item1`),
            item2: keystrokeLine(`item2`),
          },
        }),
      },
    };

    Current.api.users.deleteActivityItems = vi.fn();
    const dispatch = vi.fn();

    const thunk = deleteActivityItems(`user123`, new Date(`01-01-2022`), [`item1`]);
    thunk(dispatch, makeGetState({ users }), null);

    expect(dispatch).toHaveBeenCalledWith(
      activityItemsDeleted({ key: `user123--01-01-2022`, ids: [`item1`] }),
    );

    expect(Current.api.users.deleteActivityItems).toHaveBeenCalledWith(`user123`, [
      { id: `item1`, type: `KeystrokeLine` },
    ]);
  });
});

describe(`activityItemsDeleted`, () => {
  it(`increments numDeleted and sets item deleted bool`, () => {
    const state = reducer(
      {
        listRequest: Req.idle(),
        fetchUserRequest: {},
        users: {},
        activityOverviews: {},
        activityDays: {
          'user123--01-01-2022': Req.succeed({
            numDeleted: 0,
            items: {
              item1: keystrokeLine(`item1`),
              item2: keystrokeLine(`item2`),
            },
          }),
        },
      },
      activityItemsDeleted({ key: `user123--01-01-2022`, ids: [`item2`] }),
    );

    const day = Req.payload(state.activityDays[`user123--01-01-2022`]);
    expect(day?.numDeleted).toBe(1);
    expect(day?.items.item2?.deleted).toBe(true);
    expect(day?.items.item1?.deleted).not.toBe(true);
  });
});

// helpers

function makeGetState(state: Partial<State>): () => State {
  return () => ({
    auth: {
      admin: null,
      loginEmail: ``,
      loginPassword: ``,
      passwordLoginRequest: Req.idle(),
      requestMagicLinkRequest: Req.idle(),
      loginFromMagicLinkRequest: Req.idle(),
    },
    menu: {
      mobileSidebarOpen: false,
      desktopSidebarCollapsed: false,
      windowWidth: 0,
    },
    users: { ...initialState },
    waitlist: { email: ``, joinReq: Req.idle() },
    ...state,
  });
}

function overviewCount(
  numItems = 0,
  numCompleted = 0,
  start = new Date().toISOString(),
): GetActivityOverview_counts {
  return {
    __typename: `MonitoringRangeCounts`,
    dateRange: { __typename: `DateRange`, start },
    numItems,
    numCompleted,
  };
}

function keystrokeLine(
  id = `id-${Math.random()}`,
  appName = `appName-${Math.random()}`,
  line = `line-${Math.random()}`,
  date = new Date().toISOString(),
): ActivityItem {
  return {
    id,
    ids: [id],
    type: `KeystrokeLine`,
    appName,
    line,
    date,
  };
}
