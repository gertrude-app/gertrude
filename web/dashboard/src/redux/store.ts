import React, { JSXElementConstructor } from 'react';
import { configureStore } from '@reduxjs/toolkit';
import waitlistReducer from './slice-waitlist';
import menuReducer from './slice-menu';
import authReducer from './slice-auth';
import usersReducer from './slice-users';
import adminReducer from './slice-admin';
import storageMiddleware from './middleware-storage';
import toastMiddleware from './middleware-toast';
import redirectMiddleware from './middleware-redirect';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    admin: adminReducer,
    menu: menuReducer,
    waitlist: waitlistReducer,
    users: usersReducer,
  },
  middleware: (getDefaultMiddleware) => {
    return getDefaultMiddleware().concat([
      storageMiddleware,
      toastMiddleware,
      redirectMiddleware,
    ]);
  },
});

export type State = ReturnType<typeof store.getState>;
export type Dispatch = typeof store.dispatch;

export type QueriedProps<Component extends JSXElementConstructor<any>> =
  | { state: 'idle' }
  | { state: 'ongoing' }
  | { state: 'failed'; error?: ApiError }
  | { state: 'succeeded'; props: React.ComponentProps<Component> };

export type QueryProps<Component extends JSXElementConstructor<any>> = (
  dispatch: Dispatch,
) => (state: State) => QueriedProps<Component>;
