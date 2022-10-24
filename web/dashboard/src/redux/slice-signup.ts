import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { InitiateSignupInput } from '@dashboard/types/GraphQL';
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
  signupReq: RequestState<string | null>;
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
      state.allowingSignupsReq = Req.succeed(payload);
    });

    builder.addCase(allowingSignups.failed, (state, action) => {
      state.allowingSignupsReq = Req.fail(action.error);
    });

    builder.addCase(initiateSignup.started, (state) => {
      state.signupReq = Req.ongoing();
    });

    builder.addCase(initiateSignup.succeeded, (state, { payload }) => {
      state.signupReq = Req.succeed(payload);
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
      state.verifyEmailReq = Req.succeed(payload);
    });

    builder.addCase(verifySignupEmail.failed, (state, action) => {
      state.verifyEmailReq = Req.fail(action.error);
    });

    builder.addCase(createSignupPaymentUrl.started, (state) => {
      state.createPaymentUrlReq = Req.ongoing();
    });

    builder.addCase(createSignupPaymentUrl.succeeded, (state, { payload }) => {
      state.createPaymentUrlReq = Req.succeed(payload);
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
  Current.api.signup.joinWaitlist,
);

export const allowingSignups = createResultThunk(
  `${slice.name}/allowingSignups`,
  Current.api.signup.allowingSignups,
);

export const verifySignupEmail = createResultThunk(
  `${slice.name}/verifySignupEmail`,
  Current.api.signup.verifySignupEmail,
);

export const createSignupPaymentUrl = createResultThunk(
  `${slice.name}/createSignupPaymentUrl`,
  Current.api.signup.createSignupPaymentUrl,
);

export const handleSignupPaymentSuccess = createResultThunk(
  `${slice.name}/handleSignupPaymentSuccess`,
  Current.api.signup.handleSignupPaymentSuccess,
);

export const handleSignupPaymentCanceled = createResultThunk(
  `${slice.name}/handleSignupPaymentCanceled`,
  Current.api.signup.handleSignupPaymentCanceled,
);

export const initiateSignup = createResultThunk(
  `${slice.name}/initiateSignup`,
  (input: InitiateSignupInput) =>
    Current.api.signup.initiateSignup(input.email, input.password),
);

export const { emailUpdated, passwordUpdated } = slice.actions;

export default slice.reducer;
