import { useCallback, useReducer } from 'react';
import type { ReadOnly } from '@shared/ts-utils';
import type { Dispatch, Reducer, ReducerAction, ReducerState } from 'react';

export default function useObservedReducer<R extends Reducer<any, any>>(
  reducer: R,
  initialState: ReducerState<R>,
  observer: (state: ReadOnly<ReducerState<R>>, action: ReducerAction<R>) => unknown,
): [ReducerState<R>, Dispatch<ReducerAction<R>>] {
  const [state, dispatch] = useReducer(reducer, initialState);
  const observedDispatch: (action: ReducerAction<R>) => unknown = useCallback(
    (action) => {
      observer(state, action);
      dispatch(action);
    },
    [state, dispatch, observer],
  );
  return [state, observedDispatch];
}

export interface ReducerObserver<R extends Reducer<any, any>> {
  (state: ReadOnly<ReducerState<R>>, action: ReducerAction<R>): unknown;
}
