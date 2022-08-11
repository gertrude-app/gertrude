import { configureStore } from '@reduxjs/toolkit';
import waitlistReducer from './waitlist-slice';

export const store = configureStore({
  reducer: {
    waitlist: waitlistReducer,
  },
});

export type State = ReturnType<typeof store.getState>;
export type Dispatch = typeof store.dispatch;
