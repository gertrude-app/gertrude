import { expect, test, it, describe, vi } from 'vitest';
import { Result } from '@dash/types';
import { formatDate } from '@dash/datetime';
import { Req, editable } from '../helpers';
import Current from '../../environment';
import reducer, {
  deleteActivityItems,
  deleteDevice,
  fetchActivityOverview,
  fetchUsersActivityDay,
  fetchUsersActivityOverviews,
  newUserRouteVisited,
  upsertUser,
} from '../slice-users';
import { makeGetState, makeState } from './test-helpers';
import * as mock from './mocks';

describe(`deleteDevice`, () => {
  it(`removes device from root users state on success`, () => {
    let state = makeState((state) => {
      state.users.deleting.device = `device123`;
      state.users.entities = {
        user123: editable(
          mock.user({
            id: `user123`,
            devices: [mock.userDevice({ id: `device123` })],
          }),
        ),
      };
    }).users;

    state = reducer(state, deleteDevice.started(`device123`));
    expect(state.deleting?.device).toBeUndefined();

    state = reducer(state, deleteDevice.succeeded({ success: true }, `device123`));
    expect(state.entities.user123?.original.devices).toEqual([]);
    expect(state.entities.user123?.draft.devices).toEqual([]);
  });
});

describe(`upsertUser`, () => {
  test(`visiting new user route creates empty new user entity`, () => {
    let state = makeState().users;
    state = reducer(state, newUserRouteVisited(`abc`));
    expect(state.entities.abc?.isNew).toBe(true);
  });

  it(`with existing user, passes correct arguments to API methods`, async () => {
    const dispatch = vi.fn();
    Current.api.saveUser = vi.fn(() =>
      Promise.resolve(Result.success({ success: true })),
    );

    const user = editable(
      mock.user({
        id: `user123`,
        keyloggingEnabled: true,
        screenshotsEnabled: true,
        keychains: [
          mock.keychainSummary({ id: `keychain1` }),
          mock.keychainSummary({ id: `keychain2` }),
        ],
      }),
    );

    // here are the "edits" made to the user
    user.draft.name = `New Name`;
    user.draft.keyloggingEnabled = false;
    user.draft.screenshotsEnabled = false;
    user.draft.screenshotsResolution = 55;
    user.draft.screenshotsFrequency = 101;
    user.draft.keychains = [user.draft.keychains[0]!]; // <-- removed one

    const getState = makeGetState((state) => {
      state.auth.admin = { adminId: `admin123`, token: `` };
      state.users.entities = { user123: user };
    });

    await upsertUser(`user123`)(dispatch, getState);

    expect(Current.api.saveUser).toHaveBeenCalledWith({
      id: user.draft.id,
      name: user.draft.name,
      keyloggingEnabled: user.draft.keyloggingEnabled,
      screenshotsEnabled: user.draft.screenshotsEnabled,
      screenshotsFrequency: user.draft.screenshotsFrequency,
      screenshotsResolution: user.draft.screenshotsResolution,
      isNew: false,
      keychainIds: [`keychain1`],
    });
  });

  test(`update user happy path`, () => {
    const user = editable(mock.user({ id: `user123` }));
    user.draft.name = `Blob Jr.`; // <-- this is the edit

    const initialState = makeState((state) => {
      state.users.entities = { user123: user };
    });

    let state = reducer(initialState.users, upsertUser.started(`user123`));
    expect(state.updateUserRequest.user123).toEqual(Req.ongoing());

    state = reducer(
      initialState.users,
      upsertUser.succeeded({ success: true }, `user123`),
    );
    expect(state.updateUserRequest.user123).toEqual(Req.succeed(void 0));

    // successfully saving causes the draft state to be "committed"
    expect(state.entities.user123?.original.name).toBe(`Blob Jr.`);
  });
});

describe(`fetchUsersActivityDays`, () => {
  it(`sets the activityOverviews state correctly`, async () => {
    let state = reducer(void 0, fetchUsersActivityOverviews.started({}));
    expect(state.fetchAllActivityOverviews).toEqual(Req.ongoing());

    state = reducer(
      state,
      fetchUsersActivityOverviews.succeeded(
        [
          {
            userId: `123`,
            userName: `Keith Heijnal`,
            days: [
              mock.activityDay(5, 2, `01-01-2022`),
              mock.activityDay(11, 5, `01-05-2022`),
            ],
          },
          {
            userId: `456`,
            userName: `John Lawrence`,
            days: [],
          },
        ],
        {},
      ),
    );

    expect(state.activityOverviews).toEqual({
      123: Req.succeed({
        userName: `Keith Heijnal`,
        days: [
          mock.activityDay(11, 5, `01-05-2022`),
          mock.activityDay(5, 2, `01-01-2022`),
        ],
      }),
      456: Req.succeed({
        userName: `John Lawrence`,
        days: [],
      }),
    });
  });
});

describe(`fetchActivityOverview`, () => {
  it(`filters out ranges with no items, and orders most recent first`, async () => {
    let state = reducer(void 0, fetchActivityOverview.started({ userId: `user123` }));
    expect(state.activityOverviews).toEqual({ user123: Req.ongoing() });

    state = reducer(
      state,
      fetchActivityOverview.succeeded(
        {
          userName: `Huck`,
          days: [
            mock.activityDay(5, 0, `01-01-2022`),
            mock.activityDay(0, 0, `01-03-2022`), // <-- should be filtered out
            mock.activityDay(11, 0, `01-05-2022`), // <-- most recent, should be first
          ],
        },
        { userId: `user123` },
      ),
    );

    expect(state.activityOverviews).toEqual({
      user123: Req.succeed({
        userName: `Huck`,
        days: [
          mock.activityDay(11, 0, `01-05-2022`), // <-- most recent
          mock.activityDay(5, 0, `01-01-2022`),
        ],
      }),
    });
  });
});

describe(`deleteActivityItems`, () => {
  it(`dispatches correct action and invokes api`, () => {
    Current.api.deleteActivityItems = vi.fn();

    const getState = makeGetState((state) => {
      state.users.activityDays = {
        'user123--01-01-2022': Req.succeed({
          userName: `Bob Dylan`,
          numDeleted: 0,
          items: {
            item1: mock.keystrokeLine({ id: `item1` }),
            item2: mock.keystrokeLine({ id: `item2`, ids: [`item2`, `item3`] }),
          },
        }),
      };
    });

    deleteActivityItems({
      date: new Date(`01-01-2022`),
      itemRootIds: [`item2`],
    })(vi.fn(), getState);

    expect(Current.api.deleteActivityItems).toHaveBeenCalledWith({
      keystrokeLineIds: [`item2`, `item3`], // <-- deletes BOTH ids
      screenshotIds: [],
    });
  });

  it(`increments numDeleted and sets item deleted bool`, () => {
    const state = makeState((state) => {
      state.users.activityDays = {
        'user123--01-01-2022': Req.succeed({
          userName: `Josh`,
          numDeleted: 0,
          items: {
            item1: mock.keystrokeLine({ id: `item1` }),
            item2: mock.keystrokeLine({ id: `item2` }),
          },
        }),
      };
    });

    const next = reducer(
      state.users,
      deleteActivityItems.succeeded(
        { success: true },
        {
          date: new Date(`01-01-2022`),
          itemRootIds: [`item1`],
        },
      ),
    );

    const day = Req.payload(next.activityDays[`user123--01-01-2022`]);
    expect(day?.numDeleted).toBe(1);
    expect(day?.items.item1?.deleted).toBe(true);
  });
});

describe(`fetchUsersActivityDay`, () => {
  it(`sets the activityDays state correctly`, () => {
    const date = new Date(`01-01-2022`);
    let state = reducer(void 0, fetchUsersActivityDay.started(date));
    expect(state.fetchAllUsersDay[formatDate(date, `url`)]).toEqual(Req.ongoing());

    state = reducer(
      state,
      fetchUsersActivityDay.succeeded(
        [
          {
            userName: `Sue`,
            userId: `123`,
            numDeleted: 2,
            items: [
              {
                type: `CoalescedKeystrokeLine`,
                value: {
                  id: `123`,
                  ids: [`123`, `456`],
                  appName: `VSCode`,
                  line: `imr`,
                  createdAt: new Date(`01-01-2022`).toISOString(),
                },
              },
            ],
          },
        ],
        date,
      ),
    );

    expect(state.activityDays[`123--01-01-2022`]).toEqual(
      Req.succeed({
        userName: `Sue`,
        numDeleted: 2,
        items: {
          '123': {
            id: `123`,
            type: `KeystrokeLine`,
            ids: [`123`, `456`],
            appName: `VSCode`,
            line: `imr`,
            date: new Date(`01-01-2022`).toISOString(),
            createdAt: new Date(`01-01-2022`).toISOString(),
          },
        },
      }),
    );
  });
});
