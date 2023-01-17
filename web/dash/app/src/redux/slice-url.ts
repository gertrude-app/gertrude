import { createSlice } from '@reduxjs/toolkit';
import Current from '../environment';
import { createKeychainInitiated } from './slice-keychains';
import { createResultThunk } from './thunk';

export interface UrlState {
  redirect?: string;
}

export function initialState(): UrlState {
  return {};
}

export const slice = createSlice({
  name: `waitlist`,
  initialState,
  reducers: {
    redirectCleared: (state) => {
      delete state.redirect;
    },
  },
  extraReducers(builder) {
    builder.addCase(createKeychainInitiated, (state, { payload }) => {
      state.redirect = `/keychains/${payload.id}`;
    });
  },
});

export const joinWaitlist = createResultThunk(
  `${slice.name}/join`,
  Current.api.joinWaitlist,
);

export const { redirectCleared } = slice.actions;

export default slice.reducer;
