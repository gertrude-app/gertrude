import toast from 'react-hot-toast';
import { Action, Middleware } from '@reduxjs/toolkit';
import { capitalize } from '@dashboard/lib/string';
import { deleteActivityItems, deleteDevice, upsertUser, deleteUser } from './slice-users';
import { ResultThunk } from './thunk';
import {
  deleteKeychain,
  deleteKeyRecord,
  upsertKeychain,
  upsertEditingKeyRecord,
} from './slice-keychains';
import {
  confirmPendingNotificationMethod,
  createPendingNotificationMethod,
  deleteNotification,
  deleteNotificationMethod,
  upsertNotification,
} from './slice-admin';

const toastMiddleware: Middleware = (_store) => (next) => (action) => {
  toastCrud(`save`, `user`, upsertUser, action);
  toastCrud(`delete`, `keychain`, deleteKeychain, action);
  toastCrud(`save`, `keychain`, upsertKeychain, action);
  toastCrud(`save`, `key`, upsertEditingKeyRecord, action);
  toastCrud(`delete`, `key`, deleteKeyRecord, action);
  toastCrud(`delete`, `keychain`, deleteKeychain, action);
  toastCrud(`delete`, `device`, deleteDevice, action);
  toastCrud(`delete`, `user`, deleteUser, action);
  toastCrud(`save`, `notification`, upsertNotification, action);
  toastCrud(`delete`, `notification`, deleteNotification, action);
  toastCrud(`delete`, `notification method`, deleteNotificationMethod, action);
  toastCrud(`send`, `verification code`, createPendingNotificationMethod, action);
  toastCrud(`verify`, `confirmation code`, confirmPendingNotificationMethod, action);
  toastCrud(`approve`, `activity items`, deleteActivityItems, action);

  return next(action);
};

export default toastMiddleware;

function toastCrud(
  verb: 'save' | 'delete' | 'send' | 'verify' | 'approve',
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
    const pastTense = (() => {
      switch (verb) {
        case `save`:
          return `saved`;
        case `delete`:
          return `deleted`;
        case `send`:
          return `sent`;
        case `verify`:
          return `verified`;
        case `approve`:
          return `approved`;
      }
    })();
    toast.success(`${capitalize(type)} ${pastTense}!`);
  }

  if (thunk.failed.match(action)) {
    toast.dismiss();
    toast.error(`Failed to ${verb} ${type}`, { duration: 6000 });
  }
}
