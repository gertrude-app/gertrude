import { createSlice } from '@reduxjs/toolkit';
import type { GetIdentifiedApps } from '@dash/types';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';

export interface AppsState {
  request: RequestState<GetIdentifiedApps.Output>;
}

export function initialState(): AppsState {
  return {
    request: Req.idle(),
  };
}

export const slice = createSlice({
  name: `apps`,
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder.addCase(getIdentifiedApps.started, (state) => {
      state.request = Req.ongoing();
    });

    builder.addCase(getIdentifiedApps.failed, (state, { error }) => {
      state.request = Req.fail(error);
    });

    builder.addCase(getIdentifiedApps.succeeded, (state, { payload: apps }) => {
      state.request = Req.succeed(apps);
    });
  },
});

export const getIdentifiedApps = createResultThunk(
  `${slice.name}/getIdentifiedApps`,
  Current.api.getIdentifiedApps,
);

export default slice.reducer;
