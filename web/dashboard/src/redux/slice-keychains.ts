import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Keychain } from '../api/keychains';
import Current from '../environment';
import { commit, editable, Req, toEditableMap } from './helpers';
import { createResultThunk } from './thunk';
import * as empty from './empty';
import Result from '../api/Result';

export interface KeychainsState {
  fetchAdminKeychainRequest: Record<UUID, RequestState>;
  updateAdminKeychainRequest: Record<UUID, RequestState>;
  listAdminKeychainsRequest: RequestState;
  adminKeychains: Record<UUID, Editable<Keychain>>;
  deleting: {
    keychain?: UUID;
  };
}

type DeletableEntity = 'keychain';

export function initialState(): KeychainsState {
  return {
    fetchAdminKeychainRequest: {},
    updateAdminKeychainRequest: {},
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
    keychainEntityDeleteStarted(
      state,
      action: PayloadAction<{ type: DeletableEntity; id: UUID }>,
    ) {
      state.deleting[action.payload.type] = action.payload.id;
    },
    keychainEntityDeleteCanceled(state, action: PayloadAction<DeletableEntity>) {
      delete state.deleting[action.payload];
    },
    keychainNameUpdated(state, action: PayloadAction<{ id: UUID; name: string }>) {
      const keychain = state.adminKeychains[action.payload.id];
      if (keychain) {
        keychain.draft.name = action.payload.name;
      }
    },
    keychainDescriptionUpdated(
      state,
      action: PayloadAction<{ id: UUID; description: string }>,
    ) {
      const keychain = state.adminKeychains[action.payload.id];
      if (!keychain) {
        return;
      }
      const description = action.payload.description || null;
      keychain.draft.description = description;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(upsertKeychain.started, (state, { meta }) => {
      state.updateAdminKeychainRequest[meta.arg] = Req.ongoing();
    });

    builder.addCase(upsertKeychain.failed, (state, { error, meta }) => {
      state.updateAdminKeychainRequest[meta.arg] = Req.fail(error);
    });

    builder.addCase(upsertKeychain.succeeded, (state, { meta }) => {
      state.updateAdminKeychainRequest[meta.arg] = Req.succeed(void 0);
      const keychain = state.adminKeychains[meta.arg];
      if (keychain) {
        state.adminKeychains[meta.arg] = commit(keychain);
      }
    });

    builder.addCase(fetchAdminKeychain.started, (state, { meta }) => {
      state.fetchAdminKeychainRequest[meta.arg] = Req.ongoing();
    });

    builder.addCase(fetchAdminKeychain.failed, (state, { error, meta }) => {
      state.fetchAdminKeychainRequest[meta.arg] = Req.fail(error);
    });

    builder.addCase(fetchAdminKeychain.succeeded, (state, { payload, meta }) => {
      state.fetchAdminKeychainRequest[meta.arg] = Req.succeed(void 0);
      state.adminKeychains[payload.id] = editable(payload);
    });

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

export const fetchAdminKeychain = createResultThunk(
  `${slice.name}/fetchAdminKeychain`,
  Current.api.keychains.getAdminKeychain,
);

export const fetchAdminKeychains = createResultThunk(
  `${slice.name}/fetchAdminKeychains`,
  Current.api.keychains.listAdminKeychains,
);

export const deleteKeychain = createResultThunk(
  `${slice.name}/deleteKeychain`,
  Current.api.keychains.deleteKeychain,
);

export const upsertKeychain = createResultThunk(
  `${slice.name}/upsertKeychain`,
  async (id: UUID, { getState }) => {
    const state = getState();
    const adminId = state.auth.admin?.id ?? ``;
    const keychain = state.keychains.adminKeychains[id];
    if (!keychain) {
      return Result.unexpectedError();
    }
    return Current.api.keychains.upsertKeychain({ ...keychain, adminId });
  },
);

export const {
  keychainEntityDeleteStarted,
  keychainEntityDeleteCanceled,
  createKeychainInitiated,
  keychainDescriptionUpdated,
  keychainNameUpdated,
} = slice.actions;

export default slice.reducer;
