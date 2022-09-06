import { Middleware } from '@reduxjs/toolkit';
import { deleteUser } from './slice-users';

const redirectMiddleware: Middleware = (_store) => (next) => (action) => {
  if (deleteUser.succeeded.match(action)) {
    setTimeout(() => (window.location.href = `/users`), 500);
  }

  return next(action);
};

export default redirectMiddleware;
