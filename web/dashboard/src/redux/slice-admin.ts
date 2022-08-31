import { createSlice } from '@reduxjs/toolkit';
import { ListAdminKeychains } from '../api/admin/__generated__/ListAdminKeychains';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';

export interface AdminState {
  listKeychainsRequest: RequestState<ListAdminKeychains['keychains']>;
}

export function initialState(): AdminState {
  return {
    listKeychainsRequest: Req.idle(),
  };
}

export const slice = createSlice({
  name: `admin`,
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder.addCase(fetchAdminKeychains.started, (state) => {
      state.listKeychainsRequest = Req.ongoing();
    });

    builder.addCase(fetchAdminKeychains.succeeded, (state, { payload }) => {
      state.listKeychainsRequest = Req.succeed(payload);
    });

    builder.addCase(fetchAdminKeychains.failed, (state, { error }) => {
      state.listKeychainsRequest = Req.fail(error);
    });
  },
});

export const fetchAdminKeychains = createResultThunk(
  `${slice.name}/fetchAdminKeychains`,
  Current.api.admin.listKeychains,
);

export default slice.reducer;
