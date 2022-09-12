import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Keychain } from '../api/keychains';
import Current from '../environment';
import { editable, Req, toEditableMap } from './helpers';
import { createResultThunk } from './thunk';
import * as empty from './empty';

export interface KeychainsState {
  fetchAdminKeychainRequest: RequestState;
  listAdminKeychainsRequest: RequestState;
  adminKeychains: Record<UUID, Editable<Keychain>>;
  deleting: {
    keychain?: UUID;
  };
}

type DeletableEntity = 'keychain';

export function initialState(): KeychainsState {
  return {
    fetchAdminKeychainRequest: Req.idle(),
    listAdminKeychainsRequest: Req.idle(),
    adminKeychains: {},
    deleting: {},
  };
}

export const slice = createSlice({
  name: `keychains`,
  initialState,
  reducers: {
    createKeychainInitiated(state, action: PayloadAction<{ id: UUID; adminId: UUID }>) {
      state.adminKeychains[action.payload.id] = {
        isNew: true,
        ...editable(empty.keychain(action.payload.id, action.payload.adminId)),
      };
    },
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

export const {
  startKeychainEntityDelete,
  cancelKeychainEntityDelete,
  createKeychainInitiated,
} = slice.actions;

export default slice.reducer;
