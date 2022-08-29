import {
  AnyAction,
  ThunkAction as LibThunkAction,
  createAsyncThunk as libCreateAsycThunk,
  AsyncThunkPayloadCreator,
  AsyncThunkOptions,
} from '@reduxjs/toolkit';
import {
  TypedUseSelectorHook,
  useDispatch as libUseDispatch,
  useSelector as libUseSelector,
} from 'react-redux';
import type { State, Dispatch } from './store';

export const useDispatch: typeof libUseDispatch<Dispatch> = () =>
  libUseDispatch<Dispatch>();
export const useSelector: TypedUseSelectorHook<State> = libUseSelector;
export type ThunkAction<ReturnType = void> = LibThunkAction<
  ReturnType,
  State,
  unknown,
  AnyAction
>;

export function createAsyncThunk<
  Returned,
  ThunkArg = void,
  ThunkApiConfig extends AsyncThunkConfig = { state: State },
>(
  typePrefix: string,
  payloadCreator: AsyncThunkPayloadCreator<Returned, ThunkArg, ThunkApiConfig>,
  options?: AsyncThunkOptions<ThunkArg, ThunkApiConfig>,
): ReturnType<typeof libCreateAsycThunk<Returned, ThunkArg, ThunkApiConfig>> {
  return libCreateAsycThunk<Returned, ThunkArg, ThunkApiConfig>(
    typePrefix,
    payloadCreator,
    options,
  );
}

// copied from @reduxjs/toolkit, not exported for some reason...
type AsyncThunkConfig = {
  state?: unknown;
  dispatch?: Dispatch;
  extra?: unknown;
  rejectValue?: unknown;
  serializedErrorType?: unknown;
  pendingMeta?: unknown;
  fulfilledMeta?: unknown;
  rejectedMeta?: unknown;
};
