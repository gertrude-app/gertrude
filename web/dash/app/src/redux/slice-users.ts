import { createSlice } from '@reduxjs/toolkit';
import { formatDate } from '@dash/datetime';
import type { ActivityItem } from '@dash/components';
import type { PayloadAction } from '@reduxjs/toolkit';
import type {
  KeychainSummary,
  GetUserActivityDays,
  DateRangeInput,
  User,
} from '@dash/types';
import Current from '../environment';
import Result from '../lib/Result';
import { entireDay } from '../lib/helpers';
import { Req, toMap, toEditableMap, editable, commit } from './helpers';
import { createResultThunk } from './thunk';
import * as empty from './empty';

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
  entities: Record<UUID, Editable<User>>;
  fetchUserRequest: Record<UUID, RequestState>;
  updateUserRequest: Record<UUID, RequestState>;
  addDeviceRequest?: RequestState<number>;
  activityOverviews: Record<UUID, RequestState<GetUserActivityDays.Output>>;
  activityDays: Record<ActivityDayKey, RequestState<ActivityDay>>;
  deleting: { device?: UUID; user?: UUID };
  adding: { keychain?: KeychainSummary | null };
  deleted: UUID[];
}

export function initialState(): UsersState {
  return {
    listRequest: Req.idle(),
    entities: {},
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
    newUserRouteVisited(state, { payload: id }: PayloadAction<UUID>) {
      state.entities[id] = editable(empty.user(id), true);
    },
    userUpdated: (state, { payload }: PayloadAction<UserUpdate>) => {
      const draft = state.entities[payload.id]?.draft;
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
    keychainSelected(state, action: PayloadAction<KeychainSummary>) {
      if (state.adding.keychain?.id === action.payload.id) {
        state.adding = { keychain: null };
      } else {
        state.adding = { keychain: action.payload };
      }
    },
    keychainAdded(state, { payload }: PayloadAction<UUID>) {
      const keychain = state.adding.keychain;
      if (!keychain) return;
      state.entities[payload]?.draft.keychains.push(keychain);
      state.adding = { keychain: undefined };
    },
  },

  extraReducers: (builder) => {
    builder.addCase(fetchActivityDay.started, (state, { meta: { arg } }) => {
      state.activityDays[activityDayKey(arg.userId, arg.day)] = Req.ongoing();
    });

    builder.addCase(fetchActivityDay.succeeded, (state, { payload, meta: { arg } }) => {
      state.activityDays[activityDayKey(arg.userId, arg.day)] = Req.succeed({
        numDeleted: payload.numDeleted,
        items: toMap(
          payload.items.map((item) => {
            if (item.type === `CoalescedKeystrokeLine`) {
              return {
                type: `KeystrokeLine`,
                date: item.value.createdAt,
                ...item.value,
              };
            } else {
              return {
                type: `Screenshot`,
                date: item.value.createdAt,
                ...item.value,
              };
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
      state.entities = { ...state.entities, ...toEditableMap(action.payload) };
    });

    builder.addCase(fetchUsers.failed, (state, action) => {
      state.listRequest = Req.fail(action.error);
    });

    builder.addCase(fetchUser.succeeded, (state, { meta, payload }) => {
      state.fetchUserRequest[meta.arg] = Req.succeed(void 0);
      state.entities[meta.arg] = editable(payload);
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
        counts: action.payload.days
          .sort((a, b) => (a.date < b.date ? 1 : -1))
          .filter((day) => day.totalItems > 0),
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

    builder.addCase(upsertUser.succeeded, (state, { meta }) => {
      state.updateUserRequest[meta.arg] = Req.succeed(void 0);
      const user = state.entities[meta.arg];
      if (user) {
        state.entities[meta.arg] = commit(user);
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
      delete state.entities[meta.arg];
      state.deleted.push(meta.arg);
    });

    builder.addCase(deleteDevice.started, (state) => {
      delete state.deleting.device;
    });

    builder.addCase(deleteDevice.succeeded, (state, { meta: { arg } }) => {
      for (const [userId, user] of Object.entries(state.entities)) {
        if (user.draft.devices.some(({ id }) => id === arg)) {
          user.draft.devices = user.draft.devices.filter(({ id }) => id !== arg);
          state.entities[userId] = commit(user);
        }
      }
    });

    builder.addCase(createPendingAppConnection.started, (state) => {
      state.addDeviceRequest = Req.ongoing();
    });

    builder.addCase(createPendingAppConnection.succeeded, (state, { payload }) => {
      state.addDeviceRequest = Req.succeed(payload.code);
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
    Current.api.getUserActivityDay({ userId: arg.userId, range: entireDay(arg.day) }),
);

export const fetchActivityOverview = createResultThunk(
  `${slice.name}/fetchActivityOverview`,
  (arg: { userId: UUID; ranges?: DateRangeInput[] }) =>
    Current.api.getUserActivityDays({ userId: arg.userId, dateRanges: arg.ranges ?? [] }),
);

export const fetchUsers = createResultThunk(
  `${slice.name}/fetchUsers`,
  Current.api.getUsers,
);

export const fetchUser = createResultThunk(
  `${slice.name}/fetchUser`,
  Current.api.getUser,
);

export const deleteUser = createResultThunk(
  `${slice.name}/deleteUser`,
  async (id: UUID) => Current.api.deleteEntity({ id, type: `User` }),
);

export const deleteDevice = createResultThunk(
  `${slice.name}/deleteDevice`,
  async (id: UUID) => Current.api.deleteEntity({ id, type: `Device` }),
);

export const upsertUser = createResultThunk(
  `${slice.name}/upsertUser`,
  async (userId: UUID, { getState }) => {
    const { users, auth } = getState();
    const user = users.entities[userId];
    const adminId = auth.admin?.adminId;
    if (!user || !adminId) {
      return Result.error({ debugMessage: `User or AdminId not found` });
    }

    return Current.api.saveUser({
      ...user.draft,
      isNew: user.isNew ?? false,
      keychainIds: user.draft.keychains.map(({ id }) => id),
    });
  },
);

export const deleteActivityItems = createResultThunk(
  `${slice.name}/deleteActivityItems`,
  async (arg: { userId: UUID; date: Date; itemRootIds: UUID[] }, { getState }) => {
    const key = activityDayKey(arg.userId, arg.date);
    const day = Req.payload(getState().users.activityDays[key]);
    if (!day) {
      return Result.error({ debugMessage: `activityDay not found` });
    }

    const keystrokeLineIds: UUID[] = [];
    const screenshotIds: UUID[] = [];

    for (const id of arg.itemRootIds) {
      const item = day.items[id];
      if (item?.type === `KeystrokeLine`) {
        keystrokeLineIds.push(item.id);
      } else if (item?.type === `Screenshot`) {
        screenshotIds.push(item.id);
      }
    }

    return Current.api.deleteActivityItems({
      userId: arg.userId,
      keystrokeLineIds,
      screenshotIds,
    });
  },
);

export const createPendingAppConnection = createResultThunk(
  `${slice.name}/createPendingAppConnection`,
  Current.api.createPendingAppConnection,
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
  newUserRouteVisited,
} = slice.actions;

export default slice.reducer;

// helpers

type ActivityDayKey = string;

export function activityDayKey(userId: UUID, date: Date): ActivityDayKey {
  return `${userId}--${formatDate(date, `url`)}`;
}
