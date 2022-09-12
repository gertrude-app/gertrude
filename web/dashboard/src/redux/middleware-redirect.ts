import { Middleware } from '@reduxjs/toolkit';
import { isUnsaved } from '@shared/lib/id';
import { deleteUser, upsertUser } from './slice-users';

const redirectMiddleware: Middleware = (_store) => (next) => (action) => {
  if (deleteUser.succeeded.match(action)) {
    setTimeout(() => (window.location.href = `/users`), 500);
  }

  if (upsertUser.succeeded.match(action) && isUnsaved(action.meta.arg)) {
    window.location.href = `/users/${action.payload}`;
  }

  return next(action);
};

export default redirectMiddleware;
