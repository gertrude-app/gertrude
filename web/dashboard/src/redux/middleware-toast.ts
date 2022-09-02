import toast from 'react-hot-toast';
import { Action, Middleware } from '@reduxjs/toolkit';
import { updateUser } from './slice-users';
import { ResultThunk } from './thunk';
import { capitalize } from '../components/shared/lib/string';
import {
  deleteKeychain,
  deleteNotification,
  deleteNotificationMethod,
  updateNotification,
} from './slice-admin';

const toastMiddleware: Middleware = (_store) => (next) => (action) => {
  toastCrud(`save`, `user`, updateUser, action);
  toastCrud(`delete`, `keychain`, deleteKeychain, action);
  toastCrud(`save`, `notification`, updateNotification, action);
  toastCrud(`delete`, `notification`, deleteNotification, action);
  toastCrud(`delete`, `notification method`, deleteNotificationMethod, action);

  return next(action);
};

export default toastMiddleware;

function toastCrud(
  verb: 'save' | 'delete',
  type: string,
  thunk: ResultThunk<any, any, any>,
  action: Action<unknown>,
): void {
  if (thunk.started.match(action)) {
    toast.dismiss();
    toast.loading(`${capitalize(verb).replace(/e$/, ``)}ing ${type}...`);
  }

  if (thunk.succeeded.match(action)) {
    toast.dismiss();
    toast.success(`${capitalize(type)} ${verb}d!`);
  }

  if (thunk.failed.match(action)) {
    toast.dismiss();
    toast.error(`Failed to ${verb} ${type}`, { duration: 6000 });
  }
}
