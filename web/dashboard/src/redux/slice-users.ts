import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { formatDate } from '@dashboard/lib/dates';
import { isUnsaved, unsavedId } from '@dashboard/lib/id';
import { ActivityItem } from '@dashboard/Users/Activity/ReviewDay';
import { DateRangeInput } from '@dashboard/types/GraphQL';
import { GetActivityOverview } from '../api/users/__generated__/GetActivityOverview';
import { Req, toMap, toEditableMap, editable, commit, isDirty } from './helpers';
import { createResultThunk } from './thunk';
import Current from '../environment';
import { User } from '../api/users';
import * as empty from './empty';
import Result from '../api/Result';

interface ActivityDay {
  numDeleted: number;
  items: Record<UUID, ActivityItem>;
}

export type UserUpdate = { id: UUID } & (
  | { type: 'name'; value: string }
  | { type: 'screenshotsEnabled'; value: boolean }
  | { type: 'screenshotsResolution'; value: number }
  | { type: 'screenshotsFrequency'; value: number }
  | { type: 'keyloggingEnabled'; value: boolean }
  | { type: 'removeKeychain'; value: UUID }
);

type DeletableEntity = 'device' | 'user';

export interface UsersState {
  listRequest: RequestState;
  users: Record<UUID, Editable<User>>;
  fetchUserRequest: Record<UUID, RequestState>;
  updateUserRequest: Record<UUID, RequestState>;
  addDeviceRequest?: RequestState<number>;
  activityOverviews: Record<UUID, RequestState<GetActivityOverview>>;
  activityDays: Record<ActivityDayKey, RequestState<ActivityDay>>;
  deleting: { device?: UUID; user?: UUID };
  adding: { keychain?: Keychain | null };
  deleted: UUID[];
}

export function initialState(): UsersState {
  return {
    listRequest: Req.idle(),
    users: {
      [unsavedId()]: editable(empty.user()),
    },
    fetchUserRequest: {},
    updateUserRequest: {},
    activityOverviews: {},
    activityDays: {},
    deleting: {},
    adding: {},
    deleted: [],
  };
}

export const slice = createSlice({
  name: `users`,
  initialState,
  reducers: {
    userEntityDeleteStarted(
      state,
      action: PayloadAction<{ type: DeletableEntity; id: UUID }>,
    ) {
      state.deleting[action.payload.type] = action.payload.id;
    },
    userEntityDeleteCanceled(state, { payload: type }: PayloadAction<DeletableEntity>) {
      delete state.deleting[type];
    },
    addDeviceDismissed(state) {
      delete state.addDeviceRequest;
    },
    userUpdated: (state, { payload }: PayloadAction<UserUpdate>) => {
      const draft = state.users[payload.id]?.draft;
      if (!draft) return;
      switch (payload.type) {
        case `name`:
          draft.name = payload.value;
          break;
        case `keyloggingEnabled`:
          draft.keyloggingEnabled = payload.value;
          break;
        case `screenshotsEnabled`:
          draft.screenshotsEnabled = payload.value;
          break;
        case `screenshotsResolution`:
          draft.screenshotsResolution = payload.value;
          break;
        case `screenshotsFrequency`:
          draft.screenshotsFrequency = payload.value;
          break;
        case `removeKeychain`:
          draft.keychains = draft.keychains.filter(({ id }) => id !== payload.value);
          break;
      }
    },
    addKeychainModalDismissed(state) {
      state.adding = { keychain: undefined };
    },
    addKeychainClicked(state) {
      state.adding = { keychain: null };
    },
    keychainSelected(state, action: PayloadAction<Keychain>) {
      if (state.adding.keychain?.id === action.payload.id) {
        state.adding = { keychain: null };
      } else {
        state.adding = { keychain: action.payload };
      }
    },
    keychainAdded(state, { payload }: PayloadAction<UUID>) {
      const keychain = state.adding.keychain;
      if (!keychain) return;
      state.users[payload]?.draft.keychains.push(keychain);
      state.adding = { keychain: undefined };
    },
  },

  extraReducers: (builder) => {
    builder.addCase(fetchActivityDay.started, (state, { meta: { arg } }) => {
      state.activityDays[activityDayKey(arg.userId, arg.day)] = Req.ongoing();
    });

    builder.addCase(fetchActivityDay.succeeded, (state, { payload, meta: { arg } }) => {
      state.activityDays[activityDayKey(arg.userId, arg.day)] = Req.succeed({
        numDeleted: payload.counts[0]?.numDeleted ?? 0,
        items: toMap(
          payload.items.map((item) => {
            if (item.__typename === `CoalescedKeystrokeLine`) {
              return { ...item, type: `KeystrokeLine`, date: item.createdAt };
            } else {
              return { ...item, type: `Screenshot`, date: item.createdAt };
            }
          }),
        ),
      });
    });

    builder.addCase(fetchActivityDay.failed, (state, { error, meta: { arg } }) => {
      state.activityDays[activityDayKey(arg.userId, arg.day)] = Req.fail(error);
    });

    builder.addCase(fetchUsers.started, (state) => {
      state.listRequest = Req.ongoing();
    });

    builder.addCase(fetchUsers.succeeded, (state, action) => {
      state.listRequest = Req.succeed(void 0);
      state.users = { ...state.users, ...toEditableMap(action.payload) };
    });

    builder.addCase(fetchUsers.failed, (state, action) => {
      state.listRequest = Req.fail(action.error);
    });

    builder.addCase(fetchUser.succeeded, (state, { meta, payload }) => {
      state.fetchUserRequest[meta.arg] = Req.succeed(void 0);
      state.users[meta.arg] = editable(payload);
    });

    builder.addCase(fetchUser.failed, (state, action) => {
      state.fetchUserRequest[action.meta.arg] = Req.fail(action.error);
    });

    builder.addCase(fetchUser.started, (state, action) => {
      state.fetchUserRequest[action.meta.arg] = Req.ongoing();
    });

    builder.addCase(fetchActivityOverview.started, (state, action) => {
      state.activityOverviews[action.meta.arg.userId] = Req.ongoing();
    });

    builder.addCase(fetchActivityOverview.succeeded, (state, action) => {
      state.activityOverviews[action.meta.arg.userId] = Req.succeed({
        ...action.payload,
        counts: action.payload.counts
          .sort((a, b) => (a.dateRange.start < b.dateRange.start ? 1 : -1))
          .filter((count) => count.numItems > 0),
      });
    });

    builder.addCase(fetchActivityOverview.failed, (state, action) => {
      state.activityOverviews[action.meta.arg.userId] = Req.fail(action.error);
    });

    builder.addCase(upsertUser.started, (state, { meta }) => {
      state.updateUserRequest[meta.arg] = Req.ongoing();
    });

    builder.addCase(upsertUser.failed, (state, { meta, error }) => {
      state.updateUserRequest[meta.arg] = Req.fail(error);
    });

    builder.addCase(upsertUser.succeeded, (state, { meta, payload }) => {
      state.updateUserRequest[meta.arg] = Req.succeed(void 0);
      const user = state.users[meta.arg];
      if (user && isUnsaved(meta.arg)) {
        state.users[payload] = editable({ ...user.draft, id: payload });
        state.users[unsavedId()] = editable(empty.user());
      } else if (user) {
        state.users[meta.arg] = commit(user);
      }
    });

    builder.addCase(deleteActivityItems.succeeded, (state, action) => {
      const { userId, date, itemRootIds } = action.meta.arg;
      const day = Req.payload(state.activityDays[activityDayKey(userId, date)]);
      if (!day) {
        return;
      }

      day.numDeleted += itemRootIds.length;
      for (const id of itemRootIds) {
        const item = day.items[id];
        if (item) {
          item.deleted = true;
        }
      }
    });

    builder.addCase(deleteUser.started, (state) => {
      delete state.deleting.user;
    });

    builder.addCase(deleteUser.succeeded, (state, { meta }) => {
      delete state.users[meta.arg];
      state.deleted.push(meta.arg);
    });

    builder.addCase(deleteDevice.started, (state) => {
      delete state.deleting.device;
    });

    builder.addCase(deleteDevice.succeeded, (state, { meta: { arg } }) => {
      for (const [userId, user] of Object.entries(state.users)) {
        if (user.draft.devices.some(({ id }) => id === arg)) {
          user.draft.devices = user.draft.devices.filter(({ id }) => id !== arg);
          state.users[userId] = commit(user);
        }
      }
    });

    builder.addCase(createPendingAppConnection.started, (state) => {
      state.addDeviceRequest = Req.ongoing();
    });

    builder.addCase(createPendingAppConnection.succeeded, (state, { payload }) => {
      state.addDeviceRequest = Req.succeed(payload);
    });

    builder.addCase(createPendingAppConnection.failed, (state, { error }) => {
      state.addDeviceRequest = Req.fail(error);
    });
  },
});

// thunks

export const fetchActivityDay = createResultThunk(
  `${slice.name}/fetchActivityDay`,
  (arg: { userId: UUID; day: Date }) =>
    Current.api.users.getActivityDay(arg.userId, arg.day),
);

export const fetchActivityOverview = createResultThunk(
  `${slice.name}/fetchActivityOverview`,
  (arg: { userId: UUID; ranges?: DateRangeInput[] }) =>
    Current.api.users.getActivityOverview(arg.userId, arg.ranges),
);

export const fetchUsers = createResultThunk(
  `${slice.name}/fetchUsers`,
  Current.api.users.list,
);

export const fetchUser = createResultThunk(
  `${slice.name}/fetchUser`,
  Current.api.users.getUser,
);

export const deleteUser = createResultThunk(
  `${slice.name}/deleteUser`,
  Current.api.users.deleteUser,
);

export const deleteDevice = createResultThunk(
  `${slice.name}/deleteDevice`,
  Current.api.users.deleteDevice,
);

export const upsertUser = createResultThunk(
  `${slice.name}/upsertUser`,
  async (userId: UUID, { getState }) => {
    const { users, auth } = getState();
    const user = users.users[userId];
    const adminId = auth.admin?.id;
    if (!user || !adminId) {
      return Result.unexpectedError();
    }

    const saveResult = await Current.api.users.upsertUser({ ...user.draft, adminId });
    if (saveResult.data.type === `error`) {
      return saveResult;
    }

    if (!isDirty(user, `keychains`)) {
      return saveResult;
    }

    const serverId = saveResult.data.value;
    const setKeychainsResult = await Current.api.users.setUserKeychains(
      serverId, // in case the user was newly created, use id from server
      user.draft.keychains.map(({ id }) => id),
    );

    return setKeychainsResult.map(() => serverId);
  },
);

export const deleteActivityItems = createResultThunk(
  `${slice.name}/deleteActivityItems`,
  async (arg: { userId: UUID; date: Date; itemRootIds: UUID[] }, { getState }) => {
    const key = activityDayKey(arg.userId, arg.date);
    const day = Req.payload(getState().users.activityDays[key]);
    if (!day) {
      return Result.error<ApiError>({ type: `non_actionable` });
    }
    const apiItems = arg.itemRootIds.flatMap((id) => {
      const item = day.items[id];
      return item?.ids.map((id) => ({ id, type: item?.type ?? `Screenshot` })) ?? [];
    });

    return Current.api.users.deleteActivityItems(arg.userId, apiItems);
  },
);

export const createPendingAppConnection = createResultThunk(
  `${slice.name}/createPendingAppConnection`,
  Current.api.users.createPendingAppConnection,
);

// exports

export const {
  userUpdated,
  addDeviceDismissed,
  userEntityDeleteStarted,
  userEntityDeleteCanceled,
  addKeychainClicked,
  keychainSelected,
  keychainAdded,
  addKeychainModalDismissed,
} = slice.actions;

export default slice.reducer;

// helpers

type ActivityDayKey = string;

export function activityDayKey(userId: UUID, date: Date): ActivityDayKey {
  return `${userId}--${formatDate(date, `url`)}`;
}
