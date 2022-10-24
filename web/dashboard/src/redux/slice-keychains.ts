import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { v4 as uuid } from 'uuid';
import { newKeyState } from '@dashboard/lib/keys';
import * as EditKey from '@dashboard/lib/keys/edit';
import * as convert from '@dashboard/lib/keys/convert';
import Current from '../environment';
import { commit, editable, Req, toEditableMap } from './helpers';
import { createResultThunk } from './thunk';
import * as empty from './empty';
import editKeyReducer from './edit-key-reducer';
import Result from '../api/Result';
import { acceptUnlockRequestClicked } from './slice-unlock-requests';
import { keyForUnlockRequest } from '../lib/unlock-key';

export interface KeychainsState {
  fetchAdminKeychainRequest: Record<UUID, RequestState>;
  updateAdminKeychainRequest: Record<UUID, RequestState>;
  listAdminKeychainsRequest: RequestState;
  fetchSelectableKeychainsRequest: RequestState<{ own: Keychain[]; public: Keychain[] }>;
  saveKeyRecordRequest: RequestState;
  keychains: Record<UUID, Editable<Keychain>>;
  keyRecords: Record<UUID, Editable<KeyRecord>>;
  editingKey?: EditKey.State;
  deleting: { keychain?: UUID; key?: UUID };
  deleted: UUID[];
}

type DeletableEntity = 'keychain' | 'key';

export function initialState(): KeychainsState {
  return {
    fetchAdminKeychainRequest: {},
    updateAdminKeychainRequest: {},
    listAdminKeychainsRequest: Req.idle(),
    saveKeyRecordRequest: Req.idle(),
    fetchSelectableKeychainsRequest: Req.idle(),
    keyRecords: {},
    keychains: {},
    deleting: {},
    deleted: [],
  };
}

export const slice = createSlice({
  name: `keychains`,
  initialState,
  reducers: {
    createKeychainInitiated(state, action: PayloadAction<{ id: UUID; adminId: UUID }>) {
      state.keychains[action.payload.id] = {
        ...editable(empty.keychain(action.payload.id, action.payload.adminId)),
        isNew: true,
      };
    },
    editKeyEventReceived(state, action: PayloadAction<EditKey.Event>) {
      if (state.editingKey) {
        editKeyReducer(state.editingKey, action.payload);
      }
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
      const keychain = state.keychains[action.payload.id];
      if (keychain) {
        keychain.draft.name = action.payload.name;
      }
    },
    keychainDescriptionUpdated(
      state,
      action: PayloadAction<{ id: UUID; description: string }>,
    ) {
      const keychain = state.keychains[action.payload.id];
      if (!keychain) {
        return;
      }
      const description = action.payload.description || null;
      keychain.draft.description = description;
    },
    createNewKeyClicked(state, action: PayloadAction<UUID>) {
      const keyState = newKeyState(uuid(), action.payload);
      state.editingKey = keyState;
    },
    editKeyModalDismissed(state) {
      delete state.editingKey;
    },
    editKeyClicked(state, action: PayloadAction<UUID>) {
      const keyRecord = state.keyRecords[action.payload];
      if (keyRecord) {
        state.editingKey = convert.toState(keyRecord.original);
      }
    },
  },
  extraReducers: (builder) => {
    builder.addCase(acceptUnlockRequestClicked, (state, action) => {
      state.editingKey = convert.toState({
        id: uuid(),
        keychainId: uuid(),
        key: keyForUnlockRequest(action.payload),
      });
    });

    builder.addCase(upsertKeychain.started, (state, { meta }) => {
      state.updateAdminKeychainRequest[meta.arg] = Req.ongoing();
    });

    builder.addCase(upsertKeychain.failed, (state, { error, meta }) => {
      state.updateAdminKeychainRequest[meta.arg] = Req.fail(error);
    });

    builder.addCase(upsertKeychain.succeeded, (state, { meta }) => {
      state.updateAdminKeychainRequest[meta.arg] = Req.succeed(void 0);
      const keychain = state.keychains[meta.arg];
      if (keychain) {
        state.keychains[meta.arg] = commit(keychain);
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
      const [keychain, keyRecords] = payload;
      state.keychains[keychain.id] = editable(keychain);
      state.keyRecords = {
        ...state.keyRecords,
        ...toEditableMap(keyRecords),
      };
    });

    builder.addCase(deleteKeyRecord.started, (state) => {
      delete state.deleting.key;
    });

    builder.addCase(deleteKeyRecord.succeeded, (state, { meta }) => {
      delete state.keyRecords[meta.arg];
      state.deleted.push(meta.arg);
    });

    builder.addCase(deleteKeychain.started, (state) => {
      delete state.deleting.keychain;
    });

    builder.addCase(deleteKeychain.succeeded, (state, { meta }) => {
      delete state.keychains[meta.arg];
      state.deleted.push(meta.arg);
    });

    builder.addCase(fetchAdminKeychains.started, (state) => {
      state.listAdminKeychainsRequest = Req.ongoing();
    });

    builder.addCase(fetchAdminKeychains.succeeded, (state, { payload }) => {
      state.listAdminKeychainsRequest = Req.succeed(void 0);
      state.keychains = {
        ...state.keychains,
        ...toEditableMap(payload[0]),
      };
      state.keyRecords = {
        ...state.keyRecords,
        ...toEditableMap(payload[1]),
      };
    });

    builder.addCase(fetchAdminKeychains.failed, (state, { error }) => {
      state.listAdminKeychainsRequest = Req.fail(error);
    });

    builder.addCase(fetchSelectableKeychains.started, (state) => {
      state.fetchSelectableKeychainsRequest = Req.ongoing();
    });

    builder.addCase(fetchSelectableKeychains.failed, (state, { error }) => {
      state.fetchSelectableKeychainsRequest = Req.fail(error);
    });

    builder.addCase(fetchSelectableKeychains.succeeded, (state, { payload }) => {
      state.fetchSelectableKeychainsRequest = Req.succeed({
        own: payload.own.filter((keychain) => !keychain.isPublic),
        public: payload.public,
      });
    });

    builder.addCase(upsertEditingKeyRecord.started, (state) => {
      state.saveKeyRecordRequest = Req.ongoing();
    });

    builder.addCase(upsertEditingKeyRecord.failed, (state, { error }) => {
      state.saveKeyRecordRequest = Req.fail(error);
    });

    builder.addCase(upsertEditingKeyRecord.succeeded, (state) => {
      const savedRecord = convert.toKeyRecord(state.editingKey);
      if (savedRecord) {
        state.keyRecords[savedRecord.id] = editable(savedRecord);
      }
      delete state.editingKey;
      state.saveKeyRecordRequest = Req.succeed(void 0);
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

export const deleteKeyRecord = createResultThunk(
  `${slice.name}/deleteKeyRecord`,
  Current.api.keychains.deleteKeyRecord,
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
    const keychain = state.keychains.keychains[id];
    if (!keychain) {
      return Result.unexpectedError();
    }
    return Current.api.keychains.upsertKeychain({ ...keychain, adminId });
  },
);

export const upsertEditingKeyRecord = createResultThunk(
  `${slice.name}/upsertEditingKeyRecord`,
  async (_, { getState }) => {
    const state = getState().keychains;
    const keyRecord = convert.toKeyRecord(state.editingKey);
    if (!keyRecord) {
      return Result.unexpectedError();
    }
    return Current.api.keychains.upsertKeyRecord(
      editable(keyRecord, state.editingKey?.isNew),
    );
  },
);

export const fetchSelectableKeychains = createResultThunk(
  `${slice.name}/fetchSelectableKeychains`,
  Current.api.keychains.getSelectableKeychains,
);

export const {
  keychainEntityDeleteStarted,
  keychainEntityDeleteCanceled,
  createKeychainInitiated,
  keychainDescriptionUpdated,
  keychainNameUpdated,
  editKeyEventReceived,
  editKeyModalDismissed,
  createNewKeyClicked,
  editKeyClicked,
} = slice.actions;

export default slice.reducer;
