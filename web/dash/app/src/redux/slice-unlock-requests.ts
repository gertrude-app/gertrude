import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import * as convert from '@dash/keys';
import { RequestStatus, UnlockRequest } from '@dash/types';
import Current from '../environment';
import { editable, Req } from './helpers';
import { createResultThunk } from './thunk';
import Result from '../api/Result';

type State =
  | 'reviewing'
  | 'editingKey'
  | 'selectingKeychain'
  | 'pendingUpdate'
  | 'decided';

export interface UnlockRequestsState {
  entities: Record<UUID, UnlockRequest & { state: State }>;
  fetchReqs: Record<UUID, RequestState>;
  updateReqs: Record<UUID, RequestState>;
  detailsExpanded: boolean;
}

export function initialState(): UnlockRequestsState {
  return {
    entities: {},
    fetchReqs: {},
    updateReqs: {},
    detailsExpanded: false,
  };
}

export const slice = createSlice({
  name: `unlock-requests`,
  initialState,
  reducers: {
    detailsExpandedToggled(state) {
      state.detailsExpanded = !state.detailsExpanded;
    },
    acceptUnlockRequestClicked(state, action: PayloadAction<UnlockRequest>) {
      const unlockRequest = state.entities[action.payload.id];
      if (unlockRequest) {
        unlockRequest.state = `editingKey`;
      }
    },
    selectKeychainClicked(state, action: PayloadAction<UUID>) {
      const unlockRequest = state.entities[action.payload];
      if (unlockRequest) {
        unlockRequest.state = `selectingKeychain`;
      }
    },
  },
  extraReducers: (builder) => {
    builder.addCase(rejectUnlockRequest.started, (state, { meta }) => {
      state.updateReqs[meta.arg] = Req.ongoing();
      const unlockRequest = state.entities[meta.arg];
      if (unlockRequest) {
        unlockRequest.state = `pendingUpdate`;
      }
    });

    builder.addCase(rejectUnlockRequest.failed, (state, { error, meta }) => {
      state.updateReqs[meta.arg] = Req.fail(error);
    });

    builder.addCase(rejectUnlockRequest.succeeded, (state, { meta }) => {
      state.updateReqs[meta.arg] = Req.succeed(void 0);
      const unlockRequest = state.entities[meta.arg];
      if (unlockRequest) {
        unlockRequest.state = `decided`;
        unlockRequest.status = RequestStatus.rejected;
      }
    });

    builder.addCase(acceptUnlockRequest.started, (state, { meta }) => {
      state.updateReqs[meta.arg] = Req.ongoing();
      const unlockRequest = state.entities[meta.arg];
      if (unlockRequest) {
        unlockRequest.state = `pendingUpdate`;
      }
    });

    builder.addCase(acceptUnlockRequest.failed, (state, { error, meta }) => {
      state.updateReqs[meta.arg] = Req.fail(error);
    });

    builder.addCase(acceptUnlockRequest.succeeded, (state, { meta }) => {
      state.updateReqs[meta.arg] = Req.succeed(void 0);
      const unlockRequest = state.entities[meta.arg];
      if (unlockRequest) {
        unlockRequest.state = `decided`;
        unlockRequest.status = RequestStatus.accepted;
      }
    });

    builder.addCase(getUserUnlockRequests.started, (state, { meta }) => {
      state.fetchReqs[meta.arg] = Req.ongoing();
    });

    builder.addCase(getUserUnlockRequests.failed, (state, { error, meta }) => {
      state.fetchReqs[meta.arg] = Req.fail(error);
    });

    builder.addCase(getUserUnlockRequests.succeeded, (state, { payload, meta }) => {
      state.fetchReqs[meta.arg] = Req.succeed(void 0);
      for (const unlockRequest of payload) {
        state.entities[unlockRequest.id] = { ...unlockRequest, state: `reviewing` };
      }
    });

    builder.addCase(getUnlockRequest.started, (state, { meta }) => {
      state.detailsExpanded = false;
      state.fetchReqs[meta.arg] = Req.ongoing();
    });

    builder.addCase(getUnlockRequest.failed, (state, { error, meta }) => {
      state.fetchReqs[meta.arg] = Req.fail(error);
    });

    builder.addCase(getUnlockRequest.succeeded, (state, { payload, meta }) => {
      state.fetchReqs[meta.arg] = Req.succeed(void 0);
      state.entities[meta.arg] = {
        ...payload,
        state: payload.status === `pending` ? `reviewing` : `decided`,
      };
    });
  },
});

export const acceptUnlockRequest = createResultThunk(
  `${slice.name}/acceptUnlockRequest`,
  async (id: UUID, { getState }) => {
    const state = getState().keychains;
    const keyRecord = convert.toKeyRecord(state.editingKey);
    if (!keyRecord) {
      return Result.unexpectedError();
    }
    const insert = await Current.api.keychains.upsertKeyRecord(editable(keyRecord, true));
    if (insert.isError) {
      return insert;
    }
    return Current.api.requests.updateUnlockRequest({
      id,
      status: RequestStatus.accepted,
    });
  },
);

export const rejectUnlockRequest = createResultThunk(
  `${slice.name}/rejectUnlockRequest`,
  (id: UUID) =>
    Current.api.requests.updateUnlockRequest({ id, status: RequestStatus.rejected }),
);

export const getUnlockRequest = createResultThunk(
  `${slice.name}/getUnlockRequest`,
  Current.api.requests.getUnlockRequest,
);

export const getUserUnlockRequests = createResultThunk(
  `${slice.name}/getUserUnlockRequests`,
  Current.api.requests.getUserUnlockRequests,
);

export const {
  detailsExpandedToggled,
  selectKeychainClicked,
  acceptUnlockRequestClicked,
} = slice.actions;

export default slice.reducer;
