import toast from 'react-hot-toast';
import { Middleware } from '@reduxjs/toolkit';
import { updateUser } from './slice-users';

const toastMiddleware: Middleware = (_store) => (next) => (action) => {
  if (updateUser.started.match(action)) {
    toast.dismiss();
    toast.loading(`Saving user...`);
  }

  if (updateUser.succeeded.match(action)) {
    toast.dismiss();
    toast.success(`User saved!`);
  }

  if (updateUser.failed.match(action)) {
    toast.dismiss();
    toast.error(`Failed to save user`, { duration: 6000 });
  }

  return next(action);
};

export default toastMiddleware;
