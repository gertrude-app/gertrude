import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Keychain } from '../api/keychains';
import Current from '../environment';
import { Req, toEditableMap } from './helpers';
import { createResultThunk } from './thunk';

export interface KeychainsState {
  listAdminKeychainsRequest: RequestState;
  adminKeychains: Record<UUID, Editable<Keychain>>;
  deleting: {
    keychain?: UUID;
  };
}

type DeletableEntity = 'keychain';

export function initialState(): KeychainsState {
  return {
    listAdminKeychainsRequest: Req.idle(),
    adminKeychains: {},
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
      delete state.adminKeychains[meta.arg];
    });

    builder.addCase(fetchAdminKeychains.started, (state) => {
      state.listAdminKeychainsRequest = Req.ongoing();
    });

    builder.addCase(fetchAdminKeychains.succeeded, (state, { payload }) => {
      state.listAdminKeychainsRequest = Req.succeed(void 0);
      state.adminKeychains = {
        ...state.adminKeychains,
        ...toEditableMap(payload),
      };
    });

    builder.addCase(fetchAdminKeychains.failed, (state, { error }) => {
      state.listAdminKeychainsRequest = Req.fail(error);
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
