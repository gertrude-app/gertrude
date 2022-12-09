import type { Middleware } from '@reduxjs/toolkit';
import type { State } from './store';
import Current from '../environment';
import { submitLoginForm, logoutClicked, loginFromMagicLink } from './slice-auth';
import { desktopSidebarCollapsedToggled } from './slice-menu';
import { handleSignupPaymentSuccess } from './slice-signup';

const storageMiddleware: Middleware = (store) => (next) => (action) => {
  if (logoutClicked.match(action)) {
    Current.sessionStorage.removeItem(`admin_id`);
    Current.sessionStorage.removeItem(`admin_token`);
    Current.localStorage.removeItem(`admin_id`);
    Current.localStorage.removeItem(`admin_token`);
    if (!Current.env.isProd()) {
      Current.localStorage.setItem(`dev_logged_out`, `true`);
    }
  }

  if (
    submitLoginForm.succeeded.match(action) ||
    handleSignupPaymentSuccess.succeeded.match(action) ||
    loginFromMagicLink.succeeded.match(action)
  ) {
    const admin = action.payload;
    Current.localStorage.setItem(`admin_id`, admin.id);
    Current.localStorage.setItem(`admin_token`, admin.token);
  }

  if (desktopSidebarCollapsedToggled.match(action)) {
    const { menu }: State = store.getState();
    Current.localStorage.setItem(
      `desktop_sidebar_collapsed`,
      !menu.desktopSidebarCollapsed ? `true` : `false`,
    );
  }

  return next(action);
};

export default storageMiddleware;
