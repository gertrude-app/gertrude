import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { formatDate } from '@shared/lib/dates';
import { ActivityItem } from '@shared/dashboard/Users/Activity/ReviewDay';
import { GetActivityOverview } from '../api/users/__generated__/GetActivityOverview';
import { Req, toMap, toEditableMap, toEditable } from './helpers';
import { ThunkAction, createResultThunk } from './thunk';
import Current from '../environment';
import { DateRangeInput } from '../graphqlTypes';
import { User } from '../api/users';

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

export interface UsersState {
  listRequest: RequestState;
  users: Record<UUID, Editable<User>>;
  fetchUserRequest: Record<UUID, RequestState>;
  activityOverviews: Record<UUID, RequestState<GetActivityOverview>>;
  activityDays: Record<ActivityDayKey, RequestState<ActivityDay>>;
}

export const initialState: UsersState = {
  listRequest: Req.idle(),
  users: {},
  fetchUserRequest: {},
  activityOverviews: {},
  activityDays: {},
};

export const slice = createSlice({
  name: `users`,
  initialState,

  reducers: {
    activityItemsDeleted: (
      state,
      action: PayloadAction<{ key: ActivityDayKey; ids: UUID[] }>,
    ) => {
      const { key, ids } = action.payload;
      const day = Req.payload(state.activityDays[key]);
      if (!day) {
        return;
      }

      day.numDeleted += ids.length;
      for (const id of ids) {
        const item = day.items[id];
        if (item) {
          item.deleted = true;
        }
      }
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
      state.users[meta.arg] = toEditable(payload);
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

export function deleteActivityItems(
  userId: UUID,
  date: Date,
  itemRootIds: UUID[],
): ThunkAction {
  return async (dispatch, getState) => {
    const key = activityDayKey(userId, date);
    const day = Req.payload(getState().users.activityDays[key]);
    if (!day) {
      return;
    }

    dispatch(activityItemsDeleted({ key, ids: itemRootIds }));
    const apiItems = itemRootIds.flatMap((id) => {
      const item = day.items[id];
      return item?.ids.map((id) => ({ id, type: item?.type ?? `Screenshot` })) ?? [];
    });

    await Current.api.users.deleteActivityItems(userId, apiItems);
  };
}

// exports

export const { activityItemsDeleted, userUpdated } = slice.actions;

export default slice.reducer;

// helpers

type ActivityDayKey = string;

export function activityDayKey(userId: UUID, date: Date): ActivityDayKey {
  return `${userId}--${formatDate(date, `url`)}`;
}
