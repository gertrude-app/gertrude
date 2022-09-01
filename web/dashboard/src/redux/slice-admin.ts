import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { ListAdminKeychains } from '../api/admin/__generated__/ListAdminKeychains';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';

export interface AdminState {
  listKeychainsRequest: RequestState<ListAdminKeychains['keychains']>;
  pendingDeletionKeychainId?: UUID;
}

export function initialState(): AdminState {
  return {
    listKeychainsRequest: Req.idle(),
  };
}

export const slice = createSlice({
  name: `admin`,
  initialState,
  reducers: {
    startKeychainDelete(state, action: PayloadAction<UUID>) {
      state.pendingDeletionKeychainId = action.payload;
    },
    cancelKeychainDelete(state) {
      delete state.pendingDeletionKeychainId;
    },
  },
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

    builder.addCase(deleteKeychain.started, (state) => {
      delete state.pendingDeletionKeychainId;
    });

    builder.addCase(deleteKeychain.succeeded, (state, { meta }) => {
      if (state.listKeychainsRequest.state === `succeeded`) {
        state.listKeychainsRequest.payload = state.listKeychainsRequest.payload.filter(
          (keychain) => keychain.id !== meta.arg,
        );
      }
    });
  },
});

export const deleteKeychain = createResultThunk(
  `${slice.name}/deleteKeychain`,
  Current.api.keychains.deleteKeychain,
);

export const fetchAdminKeychains = createResultThunk(
  `${slice.name}/fetchAdminKeychains`,
  Current.api.admin.listKeychains,
);

export const { startKeychainDelete, cancelKeychainDelete } = slice.actions;

export default slice.reducer;
