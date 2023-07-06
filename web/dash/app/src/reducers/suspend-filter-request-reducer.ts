import { produce } from 'immer';
import { DURATION_OPTS } from '@dash/components';
import type { SuspendFilterRequest } from '@dash/types';

export type State = {
  request?: SuspendFilterRequest;
  responseComment: string;
  grantedDurationInSeconds: string;
  grantedCustomDurationInMinutes: string;
};

type Action =
  | { type: 'receivedRequest'; request: SuspendFilterRequest }
  | { type: 'updateComment'; comment: string }
  | { type: 'updateCustomDuration'; custom: string }
  | { type: 'updateDuration'; duration: string };

export function reducer(state: State, action: Action): State | undefined {
  switch (action.type) {
    case `receivedRequest`:
      state.request = action.request;
      state.grantedDurationInSeconds = String(action.request.requestedDurationInSeconds);
      if (!DURATION_OPTS.map((o) => o.value).includes(state.grantedDurationInSeconds)) {
        state.grantedDurationInSeconds = `custom`;
        state.grantedCustomDurationInMinutes = String(
          action.request.requestedDurationInSeconds / 60,
        );
      }
      return;

    case `updateComment`:
      state.responseComment = action.comment;
      return;

    case `updateCustomDuration`:
      state.grantedCustomDurationInMinutes = action.custom;
      return;

    case `updateDuration`:
      state.grantedDurationInSeconds = action.duration;
      return;
  }
}

export const initialState: State = {
  responseComment: ``,
  grantedDurationInSeconds: `300`,
  grantedCustomDurationInMinutes: ``,
};

export default produce(reducer);

export function durationInSeconds(state: State): number {
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
