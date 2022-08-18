import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { GetActivityOverview } from '../api/users/__generated__/GetActivityOverview';
import { ListUsers_user } from '../api/users/__generated__/ListUsers';
import Current from '../environment';
import { Req, toMap } from './helpers';

export interface UsersState {
  listReq: RequestState<Record<UUID, ListUsers_user>>;
  activityOverviews: Record<UUID, RequestState<GetActivityOverview>>;
}

const initialState: UsersState = {
  listReq: Req.idle(),
  activityOverviews: {},
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
  },
});

export const fetchActivityOverview = createAsyncThunk(
  `${slice.name}/fetchActivityOverview`,
  async (userId: UUID, { dispatch }) => {
    dispatch(activityOverviewUpdated({ userId, req: Req.ongoing() }));
    const result = await Current.api.users.getActivityOverview(userId);
    result.on({
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
    result.on({
      success: (users) => dispatch(listReqUpdated(Req.succeed(toMap(users)))),
      error: (error) => dispatch(listReqUpdated(Req.fail(error))),
    });
  },
);

export const { listReqUpdated, activityOverviewUpdated } = slice.actions;

export default slice.reducer;
