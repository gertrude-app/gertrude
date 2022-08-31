import { Middleware } from '@reduxjs/toolkit';
import { loginSucceeded, logoutClicked } from './slice-auth';
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

  if (loginSucceeded.match(action)) {
    const admin = action.payload;
    Current.localStorage.setItem(`admin_id`, admin.id);
    Current.localStorage.setItem(`admin_token`, admin.token);
  }

  return next(action);
};
