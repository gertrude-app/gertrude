import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';

export interface SignupState {
  email: string;
  allowingSignupsReq: RequestState<boolean>;
  joinWaitlistReq: RequestState;
  sendVerificationEmailReq: RequestState;
}

export function initialState(): SignupState {
  return {
    email: ``,
    allowingSignupsReq: Req.idle(),
    joinWaitlistReq: Req.idle(),
    sendVerificationEmailReq: Req.idle(),
  };
}

export const slice = createSlice({
  name: `waitlist`,
  initialState,
  reducers: {
    emailUpdated: (state, action: PayloadAction<string>) => {
      state.email = action.payload;
    },
  },
  extraReducers(builder) {
    builder.addCase(allowingSignups.started, (state) => {
      state.allowingSignupsReq = Req.ongoing();
    });

    builder.addCase(allowingSignups.succeeded, (state, { payload }) => {
      state.allowingSignupsReq = payload ? Req.succeed(payload) : Req.fail();
    });

    builder.addCase(allowingSignups.failed, (state, action) => {
      state.allowingSignupsReq = Req.fail(action.error);
    });

    builder.addCase(sendVerificationEmail.started, (state) => {
      state.sendVerificationEmailReq = Req.ongoing();
    });

    builder.addCase(sendVerificationEmail.succeeded, (state) => {
      state.sendVerificationEmailReq = Req.succeed(void 0);
    });

    builder.addCase(sendVerificationEmail.failed, (state, action) => {
      state.sendVerificationEmailReq = Req.fail(action.error);
    });

    builder.addCase(joinWaitlist.started, (state) => {
      state.joinWaitlistReq = Req.ongoing();
    });

    builder.addCase(joinWaitlist.succeeded, (state, { payload }) => {
      state.joinWaitlistReq = payload ? Req.succeed(void 0) : Req.fail();
    });

    builder.addCase(joinWaitlist.failed, (state, action) => {
      state.joinWaitlistReq = Req.fail(action.error);
    });
  },
});

export const joinWaitlist = createResultThunk(
  `${slice.name}/joinWaitlist`,
  Current.api.signup.joinWaitlist,
);

export const allowingSignups = createResultThunk(
  `${slice.name}/allowingSignups`,
  Current.api.signup.allowingSignups,
);

export const sendVerificationEmail = createResultThunk(
  `${slice.name}/sendVerificationEmail`,
  Current.api.signup.sendVerificationEmail,
);

export const { emailUpdated } = slice.actions;

export default slice.reducer;
