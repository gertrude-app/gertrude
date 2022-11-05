import { useEffect } from 'react';
import {
  TypedUseSelectorHook,
  useDispatch as libUseDispatch,
  useSelector as libUseSelector,
} from 'react-redux';
import { matchPath } from 'react-router-dom';
import { redirectCleared } from './slice-url';
import type { State, Dispatch } from './store';

export const useSelector: TypedUseSelectorHook<State> = libUseSelector;

/* eslint-disable-next-line */
export const useDispatch = () => libUseDispatch<Dispatch>();

export const useRedirect: () => string | null = () => {
  const dispatch = useDispatch();
  const redirect = useSelector((state) => state.url.redirect);

  let redirectTo: string | null = null;
  if (redirect && matchPath(redirect, window.location.pathname) === null) {
    redirectTo = redirect;
  }

  useEffect(() => {
    redirectTo && dispatch(redirectCleared());
  }, [redirectTo, dispatch]);

  return redirectTo;
};
