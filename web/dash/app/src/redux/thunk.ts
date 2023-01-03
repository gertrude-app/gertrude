import { createAction, nanoid } from '@reduxjs/toolkit';
import type {
  AnyAction,
  ThunkAction as LibThunkAction,
  ThunkDispatch,
  Action,
  ActionCreatorWithPreparedPayload,
} from '@reduxjs/toolkit';
import type { State, Dispatch } from './store';
import type Result from '../lib/Result';
import { spinnerMin } from './helpers';

export function createResultThunk<T, E, ThunkArg = void>(
  typePrefix: string,
  resultCreator: (
    arg: ThunkArg,
    helpers: { getState: () => State; dispatch: Dispatch },
  ) => Promise<Result<T, E>>,
): ResultThunk<T, E, ThunkArg> {
  const requestId = nanoid();

  const started: AsyncResultThunkStartedActionCreator<ThunkArg> = createAction(
    `${typePrefix}:started`,
    (arg: ThunkArg) => ({
      payload: undefined,
      meta: { requestId, arg },
    }),
  );

  const succeeded: AsyncResultThunkSucceededActionCreator<T, ThunkArg> = createAction(
    `${typePrefix}:succeeded`,
    (payload, arg: ThunkArg) => ({
      payload,
      meta: { requestId, arg },
    }),
  );

  const failed: AsyncResultThunkFailedActionCreator<E, ThunkArg> = createAction(
    `${typePrefix}:failed`,
    (error, arg: ThunkArg) => ({
      payload: undefined,
      error,
      meta: { requestId, arg },
    }),
  );

  const thunkCreator = (arg: ThunkArg): ThunkAction => {
    return (dispatch, getState) => {
      dispatch(started(arg));
      spinnerMin(resultCreator(arg, { dispatch: dispatch as Dispatch, getState })).then(
        (result) => {
          result.with({
            success: (payload) => dispatch(succeeded(payload, arg)),
            error: (error) => dispatch(failed(error, arg)),
          });
        },
      );
    };
  };

  return Object.assign(thunkCreator as ResultThunk<T, E, ThunkArg>, {
    started,
    succeeded,
    failed,
  });
}

type AsyncResultThunkStartedActionCreator<ThunkArg> = ActionCreatorWithPreparedPayload<
  [ThunkArg],
  undefined,
  string,
  never,
  { arg: ThunkArg; requestId: string }
>;

type AsyncResultThunkSucceededActionCreator<T, ThunkArg> =
  ActionCreatorWithPreparedPayload<
    [T, ThunkArg],
    T,
    string,
    never,
    { arg: ThunkArg; requestId: string }
  >;

type AsyncResultThunkFailedActionCreator<E, ThunkArg> = ActionCreatorWithPreparedPayload<
  [E, ThunkArg],
  void,
  string,
  E,
  { arg: ThunkArg; requestId: string }
>;

export type ResultThunk<T, E, ThunkArg = void> = ResultThunkActionCreator<ThunkArg> & {
  started: AsyncResultThunkStartedActionCreator<ThunkArg>;
  succeeded: AsyncResultThunkSucceededActionCreator<T, ThunkArg>;
  failed: AsyncResultThunkFailedActionCreator<E, ThunkArg>;
};

export type ResultThunkActionCreator<ThunkArg> = (
  arg: ThunkArg,
) => (
  dispatch: ThunkDispatch<State, void, Action>,
  getState: () => State,
) => Promise<unknown>;

export type ThunkAction<ReturnType = void> = LibThunkAction<
  ReturnType,
  State,
  unknown,
  AnyAction
>;
