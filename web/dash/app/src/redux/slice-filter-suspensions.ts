import { createSlice } from '@reduxjs/toolkit';
import { DURATION_OPTS } from '@dash/components';
import { Result } from '@dash/types';
import type { PayloadAction } from '@reduxjs/toolkit';
import type { RequestStatus, SuspendFilterRequest, RequestState } from '@dash/types';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';
import { logoutRouteVisited } from './slice-auth';

export interface FilterSuspensionsState {
  fetchReqs: Record<UUID, RequestState<SuspendFilterRequest>>;
  updateReqs: Record<UUID, RequestState>;
  responseComment: string;
  grantedDurationInSeconds: string;
  grantedCustomDurationInMinutes: string;
}

export function initialState(): FilterSuspensionsState {
  return {
    fetchReqs: {},
    updateReqs: {},
    responseComment: ``,
    grantedDurationInSeconds: `300`,
    grantedCustomDurationInMinutes: ``,
  };
}

export const slice = createSlice({
  name: `filter-suspensions`,
  initialState,
  reducers: {
    responseCommentUpdated: (state, action: PayloadAction<string>) => {
      state.responseComment = action.payload;
    },
    grantedDurationInSecondsUpdated: (state, action: PayloadAction<string>) => {
      state.grantedDurationInSeconds = action.payload;
    },
    grantedCustomDurationInMinutesUpdated: (state, action: PayloadAction<string>) => {
      state.grantedCustomDurationInMinutes = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(updateSuspendFilterRequest.started, (state, { meta }) => {
      state.updateReqs[meta.arg.id] = Req.ongoing();
    });

    builder.addCase(logoutRouteVisited, () => {
      return initialState();
    });

    builder.addCase(updateSuspendFilterRequest.failed, (state, { error, meta }) => {
      state.updateReqs[meta.arg.id] = Req.fail(error);
    });

    builder.addCase(updateSuspendFilterRequest.succeeded, (state, { meta }) => {
      state.updateReqs[meta.arg.id] = Req.succeed(void 0);
      const request = state.fetchReqs[meta.arg.id];
      if (request?.state === `succeeded`) {
        request.payload.status = meta.arg.status;
      }
    });

    builder.addCase(getSuspendFilterRequest.started, (state, { meta }) => {
      state.fetchReqs[meta.arg] = Req.ongoing();
    });

    builder.addCase(getSuspendFilterRequest.failed, (state, { error, meta }) => {
      state.fetchReqs[meta.arg] = Req.fail(error);
    });

    builder.addCase(getSuspendFilterRequest.succeeded, (state, { payload, meta }) => {
      state.fetchReqs[meta.arg] = Req.succeed(payload);
      // initialize reusable/transient form state
      const [duration, custom] = durationInit(payload.requestedDurationInSeconds);
      state.grantedDurationInSeconds = duration;
      state.grantedCustomDurationInMinutes = custom;
      state.responseComment = ``;
    });
  },
});

export const updateSuspendFilterRequest = createResultThunk(
  `${slice.name}/updateSuspendFilterRequest`,
  async (
    input: { id: UUID; status: Exclude<RequestStatus, 'pending'> },
    { getState },
  ) => {
    const state = getState().filterSuspensions;
    const request = Req.payload(state.fetchReqs[input.id]);
    if (!request) {
      return Result.unexpectedError(`f359ece0`, `Request not found`);
    }
    return Current.api.updateSuspendFilterRequest({
      id: request.id,
      durationInSeconds: grantedDurationInSeconds(state),
      responseComment: state.responseComment,
      status: input.status,
    });
  },
);

export const getSuspendFilterRequest = createResultThunk(
  `${slice.name}/getSuspendFilterRequest`,
  Current.api.getSuspendFilterRequest,
);

export const {
  responseCommentUpdated,
  grantedDurationInSecondsUpdated,
  grantedCustomDurationInMinutesUpdated,
} = slice.actions;

export default slice.reducer;

// helpers

function grantedDurationInSeconds(state: FilterSuspensionsState): number {
  const customMinutes = Number(state.grantedCustomDurationInMinutes);
  if (
    state.grantedDurationInSeconds === `custom` &&
    !isNaN(customMinutes) &&
    customMinutes >= 1
  ) {
    return customMinutes * 60;
  }
  const seconds = Number(state.grantedDurationInSeconds);
  return isNaN(seconds) || seconds < 60 ? 60 : seconds;
}

function durationInit(requested: number): [duration: string, custom: string] {
  const durationValues = DURATION_OPTS.map((o) => String(o.value));
  const duration = durationValues.find((v) => v === String(requested)) ?? `custom`;
  const custom = duration !== `custom` ? `` : String(Math.floor(requested / 60));
  return [duration, custom];
}
