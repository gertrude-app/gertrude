import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { formatDate } from '@shared/lib/dates';
import { ActivityItem } from '@shared/dashboard/Users/Activity/ReviewDay';
import Current from '../environment';
import { GetActivityDay } from '../api/users/__generated__/GetActivityDay';
import { GetActivityOverview } from '../api/users/__generated__/GetActivityOverview';
import { ListUsers_user } from '../api/users/__generated__/ListUsers';
import { Req, toMap } from './helpers';
import { ThunkAction } from './hooks';

interface ActivityDay {
  numDeleted: number;
  items: Record<UUID, ActivityItem>;
}

export interface UsersState {
  listReq: RequestState<Record<UUID, ListUsers_user>>;
  activityOverviews: Record<UUID, RequestState<GetActivityOverview>>;
  activityDays: Record<ActivityDayKey, RequestState<ActivityDay>>;
}

export const initialState: UsersState = {
  listReq: Req.idle(),
  activityOverviews: {},
  activityDays: {},
};

export const slice = createSlice({
  name: `users`,
  initialState,
  reducers: {
    listReqUpdated: (state, action: PayloadAction<UsersState['listReq']>) => {
      state.listReq = action.payload;
    },

    activityOverviewUpdated: (
      state,
      action: PayloadAction<{ userId: UUID; req: RequestState<GetActivityOverview> }>,
    ) => {
      const { userId, req } = action.payload;
      state.activityOverviews[userId] = Req.map(req, (payload) => ({
        ...payload,
        counts: payload.counts
          .sort((a, b) => (a.dateRange.start < b.dateRange.start ? 1 : -1))
          .filter((count) => count.numItems > 0),
      }));
    },

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

    activityDayUpdated: (
      state,
      action: PayloadAction<{
        key: ActivityDayKey;
        req: RequestState<GetActivityDay>;
      }>,
    ) => {
      state.activityDays[action.payload.key] = Req.map(action.payload.req, (day) => {
        return {
          numDeleted: day.counts[0]?.numDeleted ?? 0,
          items: toMap(
            day.items.map((item) => {
              if (item.__typename === `CoalescedKeystrokeLine`) {
                return {
                  type: `KeystrokeLine`,
                  id: item.id,
                  ids: item.ids,
                  appName: item.appName,
                  line: item.line,
                  date: item.createdAt,
                };
              } else {
                return {
                  type: `Screenshot`,
                  id: item.id,
                  ids: item.ids,
                  url: item.url,
                  width: item.width,
                  height: item.height,
                  date: item.createdAt,
                };
              }
            }),
          ),
        };
      });
    },
  },
});

export const fetchActivityDay = createAsyncThunk(
  `${slice.name}/fetchActivityOverview`,
  async ({ userId, day }: { userId: UUID; day: Date }, { dispatch }) => {
    const key = activityDayKey(userId, day);
    dispatch(activityDayUpdated({ key, req: Req.ongoing() }));
    const result = await Current.api.users.getActivityDay(userId, day);
    result.with({
      success: (data) => dispatch(activityDayUpdated({ key, req: Req.succeed(data) })),
      error: (error) => dispatch(activityDayUpdated({ key, req: Req.fail(error) })),
    });
  },
);

export const fetchActivityOverview = createAsyncThunk(
  `${slice.name}/fetchActivityOverview`,
  async (userId: UUID, { dispatch }) => {
    dispatch(activityOverviewUpdated({ userId, req: Req.ongoing() }));
    const result = await Current.api.users.getActivityOverview(userId);
    result.with({
      success: (data) =>
        dispatch(activityOverviewUpdated({ userId, req: Req.succeed(data) })),
      error: (error) =>
        dispatch(activityOverviewUpdated({ userId, req: Req.fail(error) })),
    });
  },
);

export const fetchUsers = createAsyncThunk(
  `${slice.name}/fetchUsers`,
  async (_, { dispatch }) => {
    dispatch(listReqUpdated(Req.ongoing()));
    const result = await Current.api.users.list();
    result.with({
      success: (users) => dispatch(listReqUpdated(Req.succeed(toMap(users)))),
      error: (error) => dispatch(listReqUpdated(Req.fail(error))),
    });
  },
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

export const {
  listReqUpdated,
  activityOverviewUpdated,
  activityDayUpdated,
  activityItemsDeleted,
} = slice.actions;

export default slice.reducer;

// helpers

type ActivityDayKey = string;

export function activityDayKey(userId: UUID, date: Date): ActivityDayKey {
  return `${userId}--${formatDate(date, `url`)}`;
}
