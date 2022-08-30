import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';

export interface WaitlistState {
  email: string;
  joinReq: RequestState;
}

const initialState: WaitlistState = {
  email: ``,
  joinReq: Req.idle(),
};

export const slice = createSlice({
  name: `waitlist`,
  initialState,
  reducers: {
    emailUpdated: (state, action: PayloadAction<string>) => {
      state.email = action.payload;
    },
  },
  extraReducers(builder) {
    builder.addCase(joinWaitlist.started, (state) => {
      state.joinReq = Req.ongoing();
    });

    builder.addCase(joinWaitlist.succeeded, (state, { payload }) => {
      state.joinReq = payload ? Req.succeed(void 0) : Req.fail();
    });

    builder.addCase(joinWaitlist.failed, (state, action) => {
      state.joinReq = Req.fail(action.error);
    });
  },
});

export const joinWaitlist = createResultThunk(
  `${slice.name}/join`,
  Current.api.signup.joinWaitlist,
);

export const { emailUpdated } = slice.actions;

export default slice.reducer;
