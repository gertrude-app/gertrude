import { createSlice } from '@reduxjs/toolkit';
import { GetIdentifiedApps_apps } from '../api/apps/__generated__/GetIdentifiedApps';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';

export interface AppsState {
  request: RequestState<GetIdentifiedApps_apps[]>;
}

export function initialState(): AppsState {
  return {
    request: Req.idle(),
  };
}

export const slice = createSlice({
  name: `menu`,
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
  Current.api.apps.getIdentifiedApps,
);

export default slice.reducer;
