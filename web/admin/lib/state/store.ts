import type { TimespanOption } from '../types';

export interface State {
  graphTimespan: TimespanOption;
}

export const initialState: State = {
  graphTimespan: `week`,
};

export type Action = {
  type: `graphTimespanOptionClicked`;
  payload: TimespanOption;
};

export function reducer(state: State, action: Action): State {
  switch (action.type) {
    case `graphTimespanOptionClicked`:
      return {
        ...state,
        graphTimespan: action.payload,
      };
  }
}
