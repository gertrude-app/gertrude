import { configureStore } from '@reduxjs/toolkit';
import waitlistReducer from './slice-waitlist';
import menuReducer from './slice-menu';
import authReducer from './slice-auth';
import { storageMiddleware } from './middleware-storage';

export const store = configureStore({
  reducer: {
    auth: authReducer,
    menu: menuReducer,
    waitlist: waitlistReducer,
  },
  middleware: (getDefaultMiddleware) => {
    return getDefaultMiddleware().concat(storageMiddleware);
  },
});

export type State = ReturnType<typeof store.getState>;
export type Dispatch = typeof store.dispatch;
