import { expect, test, it, describe, vi } from 'vitest';
import { Req, editable } from '../helpers';
import Current from '../../environment';
import reducer, {
  deleteActivityItems,
  deleteDevice,
  fetchActivityOverview,
  updateUser,
} from '../slice-users';
import { makeGetState, makeState } from './test-helpers';
import * as mock from './mocks';
import Result from '../../api/Result';

describe(`deleteDevice`, () => {
  it(`removes device from root users state on success`, () => {
    let state = makeState((state) => {
      state.users.deleting.device = `device123`;
      state.users.users = {
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

    state = reducer(state, deleteDevice.succeeded(true, `device123`));
    expect(state.users.user123?.original.devices).toEqual([]);
    expect(state.users.user123?.draft.devices).toEqual([]);
  });
});

describe(`updateUser`, () => {
  it(`passes correct arguments to API methods`, () => {
    Current.api.users.setUserKeychains = vi.fn(() => Promise.resolve(Result.true()));
    Current.api.users.updateUser = vi.fn(() => Promise.resolve(Result.true()));
    const dispatch = vi.fn();

    const user = editable(
      mock.user({
        id: `user123`,
        keyloggingEnabled: true,
        screenshotsEnabled: true,
        keychains: [
          mock.userKeychain({ id: `keychain1` }),
          mock.userKeychain({ id: `keychain2` }),
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
      state.auth.admin = { id: `admin123`, token: `` };
      state.users.users = { user123: user };
    });

    updateUser(`user123`)(dispatch, getState);

    expect(Current.api.users.updateUser).toHaveBeenCalledWith({
      ...user.draft,
      adminId: `admin123`,
    });

    expect(Current.api.users.setUserKeychains).toHaveBeenCalledWith(`user123`, [
      `keychain1`,
    ]);
  });

  test(`update user happy path`, () => {
    const user = editable(mock.user({ id: `user123` }));
    user.draft.name = `Blob Jr.`; // <-- this is the edit

    const initialState = makeState((state) => {
      state.users.users = { user123: user };
    });

    let state = reducer(initialState.users, updateUser.started(`user123`));
    expect(state.updateUserRequest.user123).toEqual(Req.ongoing());

    state = reducer(initialState.users, updateUser.succeeded([true, true], `user123`));
    expect(state.updateUserRequest.user123).toEqual(Req.succeed(void 0));

    // successfully saving causes the draft state to be "committed"
    expect(state.users.user123?.original.name).toBe(`Blob Jr.`);
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
          user: { __typename: `User`, name: `Huck` },
          counts: [
            mock.activityOverviewCounts(5, 0, `01-01-2022`),
            mock.activityOverviewCounts(0, 0, `01-03-2022`), // <-- should be filtered out
            mock.activityOverviewCounts(11, 0, `01-05-2022`), // <-- most recent, should be first
          ],
        },
        { userId: `user123` },
      ),
    );

    expect(state.activityOverviews).toEqual({
      user123: Req.succeed({
        user: { __typename: `User`, name: `Huck` },
        counts: [
          mock.activityOverviewCounts(11, 0, `01-05-2022`), // <-- most recent
          mock.activityOverviewCounts(5, 0, `01-01-2022`),
        ],
      }),
    });
  });
});

describe(`deleteActivityItems`, () => {
  it(`dispatches correct action and invokes api`, () => {
    Current.api.users.deleteActivityItems = vi.fn();

    const getState = makeGetState((state) => {
      state.users.activityDays = {
        'user123--01-01-2022': Req.succeed({
          numDeleted: 0,
          items: {
            item1: mock.keystrokeLine({ id: `item1` }),
            item2: mock.keystrokeLine({ id: `item2` }),
          },
        }),
      };
    });

    deleteActivityItems({
      userId: `user123`,
      date: new Date(`01-01-2022`),
      itemRootIds: [`item1`],
    })(vi.fn(), getState);

    expect(Current.api.users.deleteActivityItems).toHaveBeenCalledWith(`user123`, [
      { id: `item1`, type: `KeystrokeLine` },
    ]);
  });

  it(`increments numDeleted and sets item deleted bool`, () => {
    const state = makeState((state) => {
      state.users.activityDays = {
        'user123--01-01-2022': Req.succeed({
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
      deleteActivityItems.succeeded(true, {
        userId: `user123`,
        date: new Date(`01-01-2022`),
        itemRootIds: [`item1`],
      }),
    );

    const day = Req.payload(next.activityDays[`user123--01-01-2022`]);
    expect(day?.numDeleted).toBe(1);
    expect(day?.items.item1?.deleted).toBe(true);
  });
});
