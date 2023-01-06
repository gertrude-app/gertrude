import { createSlice } from '@reduxjs/toolkit';
import { v4 as uuid } from 'uuid';
import { newKeyState, convert } from '@dash/keys';
import { Result } from '@dash/types';
import type { UnlockRequest, Key, KeychainSummary, RequestState } from '@dash/types';
import type { EditKey } from '@dash/keys';
import type { PayloadAction } from '@reduxjs/toolkit';
import Current from '../environment';
import { commit, editable, Req, toEditableMap } from './helpers';
import { createResultThunk } from './thunk';
import * as empty from './empty';
import editKeyReducer from './edit-key-reducer';

export interface KeychainsState {
  fetchAdminKeychainRequest: Record<UUID, RequestState>;
  updateAdminKeychainRequest: Record<UUID, RequestState>;

  listAdminKeychainsRequest: RequestState;
  entities: Record<UUID, Editable<KeychainSummary>>;
  fetchSelectableKeychainsRequest: RequestState;

  saveKeyRecordRequest: RequestState;
  keyRecords: Record<UUID, Editable<Key>>;
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
    entities: {},
    keyRecords: {},
    deleting: {},
    deleted: [],
  };
}

export const slice = createSlice({
  name: `keychains`,
  initialState,
  reducers: {
    createKeychainInitiated(state, action: PayloadAction<{ id: UUID; adminId: UUID }>) {
      state.entities[action.payload.id] = {
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
      const keychain = state.entities[action.payload.id];
      if (keychain) {
        keychain.draft.name = action.payload.name;
      }
    },
    keychainDescriptionUpdated(
      state,
      action: PayloadAction<{ id: UUID; description: string }>,
    ) {
      const keychain = state.entities[action.payload.id];
      if (!keychain) {
        return;
      }
      keychain.draft.description = action.payload.description;
    },
    createNewKeyClicked(state, action: PayloadAction<UUID>) {
      const keyState = newKeyState(uuid(), action.payload);
      state.editingKey = keyState;
    },
    unlockRequestReviewKeyClicked(
      state,
      { payload }: PayloadAction<{ keychainId: UUID; unlockRequest: UnlockRequest }>,
    ) {
      state.editingKey = convert.unlockRequestToState(
        uuid(),
        payload.keychainId,
        payload.unlockRequest,
      );
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
    builder.addCase(upsertKeychain.started, (state, { meta }) => {
      state.updateAdminKeychainRequest[meta.arg] = Req.ongoing();
    });

    builder.addCase(upsertKeychain.failed, (state, { error, meta }) => {
      state.updateAdminKeychainRequest[meta.arg] = Req.fail(error);
    });

    builder.addCase(upsertKeychain.succeeded, (state, { meta }) => {
      state.updateAdminKeychainRequest[meta.arg] = Req.succeed(void 0);
      const keychain = state.entities[meta.arg];
      if (keychain) {
        state.entities[meta.arg] = commit(keychain);
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
      state.entities[payload.summary.id] = editable(payload.summary);
      state.keyRecords = {
        ...state.keyRecords,
        ...toEditableMap(payload.keys),
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
      delete state.entities[meta.arg];
      state.deleted.push(meta.arg);
    });

    builder.addCase(fetchAdminKeychains.started, (state) => {
      state.listAdminKeychainsRequest = Req.ongoing();
    });

    builder.addCase(fetchAdminKeychains.succeeded, (state, { payload }) => {
      state.listAdminKeychainsRequest = Req.succeed(void 0);
      state.entities = {
        ...state.entities,
        ...toEditableMap(payload.map((adminKeychain) => adminKeychain.summary)),
      };
      state.keyRecords = {
        ...state.keyRecords,
        ...toEditableMap(payload.flatMap((adminKeychain) => adminKeychain.keys)),
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
      state.fetchSelectableKeychainsRequest = Req.succeed(undefined);
      payload.own.concat(payload.public).forEach((keychain) => {
        state.entities[keychain.id] = editable(keychain);
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
  Current.api.getAdminKeychain,
);

export const fetchAdminKeychains = createResultThunk(
  `${slice.name}/fetchAdminKeychains`,
  Current.api.getAdminKeychains,
);

export const deleteKeyRecord = createResultThunk(
  `${slice.name}/deleteKeyRecord`,
  (id: UUID) => Current.api.deleteEntity({ id, type: `Key` }),
);

export const deleteKeychain = createResultThunk(
  `${slice.name}/deleteKeychain`,
  (id: UUID) => Current.api.deleteEntity({ id, type: `Keychain` }),
);

export const upsertKeychain = createResultThunk(
  `${slice.name}/upsertKeychain`,
  async (id: UUID, { getState }) => {
    const state = getState();
    const keychain = state.keychains.entities[id];
    if (!keychain) {
      return Result.unexpectedError(`e81a5099`, `Keychain not found`);
    }
    return Current.api.saveKeychain({
      isNew: keychain.isNew ?? false,
      id: keychain.draft.id,
      name: keychain.draft.name,
      description: keychain.draft.description,
      isPublic: keychain.draft.isPublic,
    });
  },
);

export const upsertEditingKeyRecord = createResultThunk(
  `${slice.name}/upsertEditingKeyRecord`,
  async (_, { getState }) => {
    const state = getState().keychains;
    const keyRecord = convert.toKeyRecord(state.editingKey);
    if (!keyRecord) {
      return Result.unexpectedError(`aa11e7f2`, `Invalid key record`);
    }
    return Current.api.saveKey({
      isNew: state.editingKey?.isNew ?? false,
      id: keyRecord.id,
      keychainId: keyRecord.keychainId,
      key: keyRecord.key,
      comment: keyRecord.comment,
      expiration: keyRecord.expiration,
    });
  },
);

export const fetchSelectableKeychains = createResultThunk(
  `${slice.name}/fetchSelectableKeychains`,
  Current.api.getSelectableKeychains,
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
  unlockRequestReviewKeyClicked,
} = slice.actions;

export default slice.reducer;
