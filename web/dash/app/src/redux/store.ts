import { configureStore } from '@reduxjs/toolkit';
import type { JSXElementConstructor } from 'react';
import type React from 'react';
import signupReducer from './slice-signup';
import menuReducer from './slice-menu';
import authReducer from './slice-auth';
import usersReducer from './slice-users';
import adminReducer from './slice-admin';
import keychainsReducer from './slice-keychains';
import urlReducer from './slice-url';
import appsReducer from './slice-apps';
import dashboardReducer from './slice-dashboard';
import filterSuspensionsReducer from './slice-filter-suspensions';
import unlockRequestsReducer from './slice-unlock-requests';
import storageMiddleware from './middleware-storage';
import toastMiddleware from './middleware-toast';

export const store = configureStore({
  reducer: {
    admin: adminReducer,
    apps: appsReducer,
    auth: authReducer,
    dashboard: dashboardReducer,
    keychains: keychainsReducer,
    menu: menuReducer,
    filterSuspensions: filterSuspensionsReducer,
    signup: signupReducer,
    users: usersReducer,
    unlockRequests: unlockRequestsReducer,
    url: urlReducer,
  },
  middleware: (getDefaultMiddleware) => {
    return getDefaultMiddleware().concat([storageMiddleware, toastMiddleware]);
  },
});

export type State = ReturnType<typeof store.getState>;
export type Dispatch = typeof store.dispatch;

export type QueriedProps<Component extends JSXElementConstructor<any>> =
  | { state: 'shouldFetch' }
  | { state: 'ongoing' }
  | { state: 'entityDeleted'; redirectUrl: string }
  | { state: 'failed'; error?: PqlError }
  | { state: 'resolved'; props: React.ComponentProps<Component> };

export type QueryProps<Component extends JSXElementConstructor<any>, ExtraArg = void> = (
  dispatch: Dispatch,
  extraArg: ExtraArg,
) => (state: State) => [query: QueriedProps<Component>, shouldFetch: boolean];
