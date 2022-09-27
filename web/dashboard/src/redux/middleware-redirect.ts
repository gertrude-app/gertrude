import { Middleware } from '@reduxjs/toolkit';
import { isUnsaved } from '@dashboard/lib/id';
import { upsertUser } from './slice-users';

const redirectMiddleware: Middleware = (_store) => (next) => (action) => {
  if (upsertUser.succeeded.match(action) && isUnsaved(action.meta.arg)) {
    window.location.href = `/users/${action.payload}`;
  }

  return next(action);
};

export default redirectMiddleware;
