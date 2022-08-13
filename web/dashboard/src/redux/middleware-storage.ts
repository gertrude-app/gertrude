import { Middleware } from '@reduxjs/toolkit';
import { logoutClicked } from './slice-auth';
import Current from '../environment';

export const storageMiddleware: Middleware = (_store) => (next) => (action) => {
  if (logoutClicked.match(action)) {
    Current.sessionStorage.removeItem(`admin_id`);
    Current.sessionStorage.removeItem(`admin_token`);
    Current.localStorage.removeItem(`admin_id`);
    Current.localStorage.removeItem(`admin_token`);
    if (!Current.env.isProd()) {
      Current.sessionStorage.setItem(`dev_logged_out`, `true`);
    }
  }
  return next(action);
};
