import { Middleware } from '@reduxjs/toolkit';
import { isUnsaved } from '@shared/lib/id';
import { deleteUser, upsertUser } from './slice-users';
import { deleteKeychain } from './slice-keychains';

const redirectMiddleware: Middleware = (_store) => (next) => (action) => {
  if (deleteUser.succeeded.match(action)) {
    setTimeout(() => (window.location.href = `/users`), 500);
  }

  if (upsertUser.succeeded.match(action) && isUnsaved(action.meta.arg)) {
    window.location.href = `/users/${action.payload}`;
  }

  if (
    deleteKeychain.succeeded.match(action) &&
    window.location.pathname.match(/^\/keychains\/[a-f0-9]{8}-/)
  ) {
    setTimeout(() => (window.location.href = `/keychains`), 500);
  }

  return next(action);
};

export default redirectMiddleware;
