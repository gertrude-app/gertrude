import { createSlice } from '@reduxjs/toolkit';
import type { PayloadAction } from '@reduxjs/toolkit';
import Current from '../environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';

export interface SignupState {
  email: string;
  password: string;
  allowingSignupsReq: RequestState<boolean>;
  joinWaitlistReq: RequestState;
  createPaymentUrlReq: RequestState<string>;
  verifyEmailReq: RequestState<UUID>;
  checkoutSuccessReq: RequestState;
  signupReq: RequestState<string | undefined>;
}

export function initialState(): SignupState {
  return {
    email: ``,
    password: ``,
    allowingSignupsReq: Req.idle(),
    createPaymentUrlReq: Req.idle(),
    joinWaitlistReq: Req.idle(),
    verifyEmailReq: Req.idle(),
    checkoutSuccessReq: Req.idle(),
    signupReq: Req.idle(),
  };
}

export const slice = createSlice({
  name: `signup`,
  initialState,
  reducers: {
    emailUpdated: (state, action: PayloadAction<string>) => {
      state.email = action.payload;
    },
    passwordUpdated: (state, action: PayloadAction<string>) => {
      state.password = action.payload;
    },
  },
  extraReducers(builder) {
    builder.addCase(allowingSignups.started, (state) => {
      state.allowingSignupsReq = Req.ongoing();
    });

    builder.addCase(allowingSignups.succeeded, (state, { payload }) => {
      state.allowingSignupsReq = Req.succeed(payload.success);
    });

    builder.addCase(allowingSignups.failed, (state, action) => {
      state.allowingSignupsReq = Req.fail(action.error);
    });

    builder.addCase(initiateSignup.started, (state) => {
      state.signupReq = Req.ongoing();
    });

    builder.addCase(initiateSignup.succeeded, (state, { payload }) => {
      state.signupReq = Req.succeed(payload.url);
    });

    builder.addCase(initiateSignup.failed, (state, action) => {
      state.signupReq = Req.fail(action.error);
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

    builder.addCase(verifySignupEmail.started, (state) => {
      state.verifyEmailReq = Req.ongoing();
    });

    builder.addCase(verifySignupEmail.succeeded, (state, { payload }) => {
      state.verifyEmailReq = Req.succeed(payload.adminId);
    });

    builder.addCase(verifySignupEmail.failed, (state, action) => {
      // ignore react strict mode second request failure
      if (state.verifyEmailReq.state !== `succeeded`) {
        state.verifyEmailReq = Req.fail(action.error);
      }
    });

    builder.addCase(createSignupPaymentUrl.started, (state) => {
      state.createPaymentUrlReq = Req.ongoing();
    });

    builder.addCase(createSignupPaymentUrl.succeeded, (state, { payload }) => {
      state.createPaymentUrlReq = Req.succeed(payload.url);
    });

    builder.addCase(createSignupPaymentUrl.failed, (state, action) => {
      state.createPaymentUrlReq = Req.fail(action.error);
    });

    builder.addCase(handleSignupPaymentSuccess.started, (state) => {
      state.checkoutSuccessReq = Req.ongoing();
    });

    builder.addCase(handleSignupPaymentSuccess.succeeded, (state) => {
      state.checkoutSuccessReq = Req.succeed(void 0);
    });

    builder.addCase(handleSignupPaymentSuccess.failed, (state, action) => {
      state.checkoutSuccessReq = Req.fail(action.error);
    });
  },
});

export const joinWaitlist = createResultThunk(
  `${slice.name}/joinWaitlist`,
  Current.api.joinWaitlist,
);

export const allowingSignups = createResultThunk(
  `${slice.name}/allowingSignups`,
  Current.api.allowingSignups,
);

export const verifySignupEmail = createResultThunk(
  `${slice.name}/verifySignupEmail`,
  Current.api.verifySignupEmail,
);

export const createSignupPaymentUrl = createResultThunk(
  `${slice.name}/createSignupPaymentUrl`,
  Current.api.getCheckoutUrl,
);

export const handleSignupPaymentSuccess = createResultThunk(
  `${slice.name}/handleSignupPaymentSuccess`,
  Current.api.handleCheckoutSuccess,
);

export const handleSignupPaymentCanceled = createResultThunk(
  `${slice.name}/handleSignupPaymentCanceled`,
  Current.api.handleCheckoutCancel,
);

export const initiateSignup = createResultThunk(
  `${slice.name}/initiateSignup`,
  Current.api.signup,
);

export const { emailUpdated, passwordUpdated } = slice.actions;

export default slice.reducer;
