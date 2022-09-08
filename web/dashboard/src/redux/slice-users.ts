import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { formatDate } from '@shared/lib/dates';
import { ActivityItem } from '@dashboard/Users/Activity/ReviewDay';
import { DateRangeInput } from '@dashboard/types/GraphQL';
import { GetActivityOverview } from '../api/users/__generated__/GetActivityOverview';
import { Req, toMap, toEditableMap, editable, commit } from './helpers';
import { createResultThunk } from './thunk';
import Current from '../environment';
import { User } from '../api/users';
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
  activityOverviews: Record<UUID, RequestState<GetActivityOverview>>;
  activityDays: Record<ActivityDayKey, RequestState<ActivityDay>>;
  deleting: {
    device?: UUID;
    user?: UUID;
  };
}

export function initialState(): UsersState {
  return {
    listRequest: Req.idle(),
    users: {},
    fetchUserRequest: {},
    updateUserRequest: {},
    activityOverviews: {},
    activityDays: {},
    deleting: {},
  };
}

export const slice = createSlice({
  name: `users`,
  initialState,
  reducers: {
    startEntityDelete(state, action: PayloadAction<{ type: DeletableEntity; id: UUID }>) {
      state.deleting[action.payload.type] = action.payload.id;
    },
    cancelEntityDelete(state, { payload: type }: PayloadAction<DeletableEntity>) {
      delete state.deleting[type];
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

    builder.addCase(updateUser.started, (state, { meta }) => {
      state.updateUserRequest[meta.arg] = Req.ongoing();
    });

    builder.addCase(updateUser.failed, (state, { meta, error: [error] }) => {
      state.updateUserRequest[meta.arg] = Req.fail(error);
    });

    builder.addCase(updateUser.succeeded, (state, { meta }) => {
      state.updateUserRequest[meta.arg] = Req.succeed(void 0);
      const user = state.users[meta.arg];
      user && (state.users[meta.arg] = commit(user));
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

    builder.addCase(deleteUser.succeeded, (state, action) => {
      delete state.users[action.meta.arg];
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

export const updateUser = createResultThunk(
  `${slice.name}/updateUser`,
  async (userId: UUID, { getState }) => {
    const { users, auth } = getState();
    const user = users.users[userId]?.draft;
    if (!user || !auth.admin?.id) {
      return Result.error<[ApiError]>([{ type: `non_actionable` }]);
    }
    const [updateUserResult, setKeychainsResult] = await Promise.all([
      Current.api.users.updateUser({ ...user, adminId: auth.admin.id }),
      Current.api.users.setUserKeychains(
        userId,
        user.keychains.map(({ id }) => id),
      ),
    ]);
    return Result.merge(updateUserResult, setKeychainsResult);
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

// exports

export const { userUpdated, startEntityDelete, cancelEntityDelete } = slice.actions;

export default slice.reducer;

// helpers

type ActivityDayKey = string;

export function activityDayKey(userId: UUID, date: Date): ActivityDayKey {
  return `${userId}--${formatDate(date, `url`)}`;
}
