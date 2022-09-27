import React, { JSXElementConstructor } from 'react';
import { configureStore } from '@reduxjs/toolkit';
import waitlistReducer from './slice-waitlist';
import menuReducer from './slice-menu';
import authReducer from './slice-auth';
import usersReducer from './slice-users';
import adminReducer from './slice-admin';
import keychainsReducer from './slice-keychains';
import urlReducer from './slice-url';
import appsReducer from './slice-apps';
import storageMiddleware from './middleware-storage';
import toastMiddleware from './middleware-toast';
import redirectMiddleware from './middleware-redirect';

export const store = configureStore({
  reducer: {
    admin: adminReducer,
    apps: appsReducer,
    auth: authReducer,
    keychains: keychainsReducer,
    menu: menuReducer,
    waitlist: waitlistReducer,
    users: usersReducer,
    url: urlReducer,
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
  | { state: 'shouldFetch' }
  | { state: 'ongoing' }
  | { state: 'entityDeleted'; redirectUrl: string }
  | { state: 'failed'; error?: ApiError }
  | { state: 'resolved'; props: React.ComponentProps<Component> };

export type QueryProps<Component extends JSXElementConstructor<any>, ExtraArg = void> = (
  dispatch: Dispatch,
  extraArg: ExtraArg,
) => (state: State) => [query: QueriedProps<Component>, shouldFetch: boolean];
