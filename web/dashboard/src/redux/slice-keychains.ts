import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { ListAdminKeychains } from '../api/admin/__generated__/ListAdminKeychains';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';

export interface KeychainsState {
  listKeychainsRequest: RequestState<ListAdminKeychains['keychains']>;
  deleting: {
    keychain?: UUID;
  };
}

type DeletableEntity = 'keychain';

export function initialState(): KeychainsState {
  return {
    listKeychainsRequest: Req.idle(),
    deleting: {},
  };
}

export const slice = createSlice({
  name: `keychains`,
  initialState,
  reducers: {
    startKeychainEntityDelete(
      state,
      action: PayloadAction<{ type: DeletableEntity; id: UUID }>,
    ) {
      state.deleting[action.payload.type] = action.payload.id;
    },
    cancelKeychainEntityDelete(state, { payload: type }: PayloadAction<DeletableEntity>) {
      delete state.deleting[type];
    },
  },
  extraReducers: (builder) => {
    builder.addCase(deleteKeychain.started, (state) => {
      delete state.deleting.keychain;
    });

    builder.addCase(deleteKeychain.succeeded, (state, { meta }) => {
      if (state.listKeychainsRequest.state === `succeeded`) {
        state.listKeychainsRequest.payload = state.listKeychainsRequest.payload.filter(
          (keychain) => keychain.id !== meta.arg,
        );
      }
    });

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

export const deleteKeychain = createResultThunk(
  `${slice.name}/deleteKeychain`,
  Current.api.keychains.deleteKeychain,
);

export const { startKeychainEntityDelete, cancelKeychainEntityDelete } = slice.actions;

export default slice.reducer;
