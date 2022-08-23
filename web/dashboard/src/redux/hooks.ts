import { AnyAction, ThunkAction as LibThunkAction } from '@reduxjs/toolkit';
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
