import { createSlice } from '@reduxjs/toolkit';
import type { DashboardWidgetData } from '@dash/types';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';
import { acceptUnlockRequest, rejectUnlockRequest } from './slice-unlock-requests';
import { deleteActivityItems } from './slice-users';

export interface DashboardState {
  request: RequestState<DashboardWidgetData>;
}

export function initialState(): DashboardState {
  return {
    request: Req.idle(),
  };
}

export const slice = createSlice({
  name: `dashboard`,
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder.addCase(fetchDashboardData.started, (state) => {
      state.request = Req.ongoing();
    });
    builder.addCase(fetchDashboardData.failed, (state, { error }) => {
      state.request = Req.fail(error);
    });
    builder.addCase(fetchDashboardData.succeeded, (state, action) => {
      state.request = Req.succeed(action.payload);
    });

    builder.addCase(rejectUnlockRequest.succeeded, (state, action) => {
      const payload = Req.payload(state.request);
      if (payload) {
        payload.unlockRequests = payload.unlockRequests.filter(
          (unlockReq) => unlockReq.id !== action.meta.arg,
        );
      }
    });

    builder.addCase(acceptUnlockRequest.succeeded, (state, action) => {
      const payload = Req.payload(state.request);
      if (payload) {
        payload.unlockRequests = payload.unlockRequests.filter(
          (unlockReq) => unlockReq.id !== action.meta.arg,
        );
      }
    });

    builder.addCase(deleteActivityItems.succeeded, (state, { meta: { arg } }) => {
      const payload = Req.payload(state.request);
      if (!payload) return;
      const user = payload.userActivity.find((user) => user.id === arg.userId);
      if (user) {
        user.numUnreviewed -= arg.itemRootIds.length;
      }
    });
  },
});

export const fetchDashboardData = createResultThunk(
  `${slice.name}/fetchDashboardData`,
  Current.api.dashboard.getWidgets,
);

export default slice.reducer;
