import { configureStore } from '@reduxjs/toolkit';
import waitlistReducer from './slice-waitlist';
import menuReducer from './slice-menu';
import authReducer from './slice-auth';
import usersReducer from './slice-users';
import adminReducer from './slice-admin';
import storageMiddleware from './middleware-storage';
import toastMiddleware from './middleware-toast';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    admin: adminReducer,
    menu: menuReducer,
    waitlist: waitlistReducer,
    users: usersReducer,
  },
  middleware: (getDefaultMiddleware) => {
    return getDefaultMiddleware().concat([storageMiddleware, toastMiddleware]);
  },
});

export type State = ReturnType<typeof store.getState>;
export type Dispatch = typeof store.dispatch;
