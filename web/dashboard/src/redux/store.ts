import { configureStore } from '@reduxjs/toolkit';
import waitlistReducer from './waitlist-slice';
import menuReducer from './menu-slice';

export const store = configureStore({
  reducer: {
    menu: menuReducer,
    waitlist: waitlistReducer,
  },
});

export type State = ReturnType<typeof store.getState>;
export type Dispatch = typeof store.dispatch;
