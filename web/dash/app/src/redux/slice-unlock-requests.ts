import { createSlice } from '@reduxjs/toolkit';
import * as convert from '@dash/keys';
import { RequestStatus } from '@dash/types';
import type { UnlockRequest } from '@dash/types';
import type { PayloadAction } from '@reduxjs/toolkit';
import Current from '../environment';
import Result from '../lib/Result';
import { editable, Req } from './helpers';
import { createResultThunk } from './thunk';

export interface UnlockRequestsState {
  entities: Record<UUID, UnlockRequest>;
  fetchAllReq: RequestState;
  fetchReqs: Record<UUID, RequestState>;
  updateReqs: Record<UUID, RequestState>;
  denyComment?: string;
  detailsExpanded: boolean;
  selectedKeychainId?: UUID;
}

export function initialState(): UnlockRequestsState {
  return {
    entities: {},
    fetchReqs: {},
    fetchAllReq: Req.idle(),
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
    keychainSelected(state, action: PayloadAction<UUID>) {
      state.selectedKeychainId = action.payload;
    },
    denyCommentUpdated(state, action: PayloadAction<string>) {
      state.denyComment = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(rejectUnlockRequest.started, (state, { meta }) => {
      state.updateReqs[meta.arg] = Req.ongoing();
    });

    builder.addCase(rejectUnlockRequest.failed, (state, { error, meta }) => {
      state.updateReqs[meta.arg] = Req.fail(error);
    });

    builder.addCase(rejectUnlockRequest.succeeded, (state, { meta }) => {
      state.updateReqs[meta.arg] = Req.succeed(void 0);
      state.detailsExpanded = false;
      state.selectedKeychainId = undefined;
      state.denyComment = undefined;
      const unlockRequest = state.entities[meta.arg];
      if (unlockRequest) {
        unlockRequest.status = RequestStatus.rejected;
      }
    });

    builder.addCase(acceptUnlockRequest.started, (state, { meta }) => {
      state.updateReqs[meta.arg] = Req.ongoing();
    });

    builder.addCase(acceptUnlockRequest.failed, (state, { error, meta }) => {
      state.updateReqs[meta.arg] = Req.fail(error);
    });

    builder.addCase(acceptUnlockRequest.succeeded, (state, { meta }) => {
      state.updateReqs[meta.arg] = Req.succeed(void 0);
      state.detailsExpanded = false;
      state.selectedKeychainId = undefined;
      const unlockRequest = state.entities[meta.arg];
      if (unlockRequest) {
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
        state.entities[unlockRequest.id] = unlockRequest;
      }
    });

    builder.addCase(getUsersUnlockRequests.started, (state) => {
      state.fetchAllReq = Req.ongoing();
    });

    builder.addCase(getUsersUnlockRequests.failed, (state, { error }) => {
      state.fetchAllReq = Req.fail(error);
    });

    builder.addCase(getUsersUnlockRequests.succeeded, (state, { payload }) => {
      state.fetchAllReq = Req.succeed(void 0);
      for (const unlockRequest of payload) {
        state.entities[unlockRequest.id] = unlockRequest;
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
      state.entities[meta.arg] = payload;
    });
  },
});

export const acceptUnlockRequest = createResultThunk(
  `${slice.name}/acceptUnlockRequest`,
  async (id: UUID, { getState }) => {
    const keyRecord = convert.toKeyRecord(getState().keychains.editingKey);
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
  (id: UUID, { getState }) => {
    const comment = getState().unlockRequests.denyComment?.trim();
    return Current.api.requests.updateUnlockRequest({
      id,
      status: RequestStatus.rejected,
      responseComment: comment || undefined,
    });
  },
);

export const getUnlockRequest = createResultThunk(
  `${slice.name}/getUnlockRequest`,
  Current.api.requests.getUnlockRequest,
);

export const getUsersUnlockRequests = createResultThunk(
  `${slice.name}/getUsersUnlockRequests`,
  Current.api.requests.getUsersUnlockRequests,
);

export const getUserUnlockRequests = createResultThunk(
  `${slice.name}/getUserUnlockRequests`,
  Current.api.requests.getUserUnlockRequests,
);

export const { detailsExpandedToggled, denyCommentUpdated, keychainSelected } =
  slice.actions;

export default slice.reducer;
