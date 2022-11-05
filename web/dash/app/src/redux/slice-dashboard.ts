import { createSlice } from '@reduxjs/toolkit';
import type { DashboardWidgetData } from '@dash/types';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';

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
  },
});

export const fetchDashboardData = createResultThunk(
  `${slice.name}/fetchDashboardData`,
  Current.api.dashboard.getWidgets,
);

export default slice.reducer;
