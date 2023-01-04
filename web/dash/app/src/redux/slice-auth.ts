import { createSlice } from '@reduxjs/toolkit';
import { env } from '@shared/components';
import type { PayloadAction } from '@reduxjs/toolkit';
import type { Login } from '@dash/types';
import type { StorageClient } from '../environment/Storage';
import Current from '../environment';
import { OptionalVar as Optional } from '../environment/Environment';
import { Req } from './helpers';
import { createResultThunk } from './thunk';
import { handleSignupPaymentSuccess } from './slice-signup';

type AdminIds = Login.Output;

export interface AuthState {
  admin: AdminIds | null;
  loginEmail: string;
  loginPassword: string;
  passwordLoginRequest: RequestState;
  requestMagicLinkRequest: RequestState;
  loginFromMagicLinkRequest: RequestState;
}

export function initialState(): AuthState {
  return {
    admin: getInitialAdmin(),
    loginEmail: ``,
    loginPassword: ``,
    passwordLoginRequest: Req.idle(),
    requestMagicLinkRequest: Req.idle(),
    loginFromMagicLinkRequest: Req.idle(),
  };
}

export const slice = createSlice({
  name: `auth`,
  initialState,
  reducers: {
    errorExpired: (state) => {
      state.passwordLoginRequest = Req.idle();
      state.requestMagicLinkRequest = Req.idle();
      state.loginFromMagicLinkRequest = Req.idle();
    },
    loginEmailUpdated: (state, action: PayloadAction<string>) => {
      state.loginEmail = action.payload;
    },
    loginPasswordUpdated: (state, action: PayloadAction<string>) => {
      state.loginPassword = action.payload;
    },
    logoutRouteVisited: (state) => {
      state.admin = null;
      state.passwordLoginRequest = Req.idle();
    },
    logoutClicked: (state) => {
      state.admin = null;
      state.passwordLoginRequest = Req.idle();
    },
  },

  extraReducers: (builder) => {
    builder.addCase(submitLoginForm.started, (state) => {
      state.passwordLoginRequest = Req.ongoing();
    });

    builder.addCase(submitLoginForm.succeeded, (state, { payload: admin }) => {
      state.admin = admin;
      state.passwordLoginRequest = Req.succeed(void 0);
      state.loginEmail = ``;
      state.loginPassword = ``;
    });

    builder.addCase(submitLoginForm.failed, (state, action) => {
      state.passwordLoginRequest = Req.fail(action.error);
    });

    builder.addCase(requestMagicLink.started, (state) => {
      state.requestMagicLinkRequest = Req.ongoing();
    });

    builder.addCase(requestMagicLink.succeeded, (state) => {
      state.requestMagicLinkRequest = Req.succeed(void 0);
    });

    builder.addCase(requestMagicLink.failed, (state, action) => {
      state.requestMagicLinkRequest = Req.fail(action.error);
    });

    builder.addCase(loginFromMagicLink.started, (state) => {
      state.loginFromMagicLinkRequest = Req.ongoing();
    });

    builder.addCase(loginFromMagicLink.succeeded, (state, { payload: admin }) => {
      state.admin = admin;
      state.loginFromMagicLinkRequest = Req.succeed(void 0);
      state.loginEmail = ``;
      state.loginPassword = ``;
    });

    builder.addCase(loginFromMagicLink.failed, (state, action) => {
      state.loginFromMagicLinkRequest = Req.fail(action.error);
    });

    builder.addCase(handleSignupPaymentSuccess.succeeded, (state, { payload: admin }) => {
      state.admin = admin;
    });
  },
});

export const submitLoginForm = createResultThunk(
  `${slice.name}/submitLoginForm`,
  async (_, { getState, dispatch }) => {
    const { loginEmail, loginPassword } = getState().auth;
    const result = await Current.api.login({
      email: loginEmail,
      password: loginPassword,
    });
    result.withError(() => setTimeout(() => dispatch(errorExpired()), 6000));
    return result;
  },
);

export const requestMagicLink = createResultThunk(
  `${slice.name}/requestMagicLink`,
  (_, { getState }) =>
    Current.api.requestMagicLink({
      email: getState().auth.loginEmail,
      redirect: new URLSearchParams(window.location.search).get(`redirect`) ?? undefined,
    }),
);

export const loginFromMagicLink = createResultThunk(
  `${slice.name}/loginFromMagicLink`,
  Current.api.loginMagicLink,
);

const { errorExpired } = slice.actions;

export const {
  logoutClicked,
  logoutRouteVisited,
  loginEmailUpdated,
  loginPasswordUpdated,
} = slice.actions;

export default slice.reducer;

// helpers

export function getInitialAdmin(): AdminIds | null {
  if (import.meta.env.VITEST) {
    return null;
  }

  const ids = adminFrom(Current.localStorage) ?? adminFrom(Current.sessionStorage);
  if (ids || Current.env.isProd() || env.isCypress()) {
    return ids;
  }

  if (window.location.pathname === `/login`) {
    return null;
  }

  if (Current.localStorage.getItem(`dev_logged_out`) !== null) {
    return null;
  }

  const devCreds = Current.env.optionalVar(Optional.TestAdminCreds);
  if (!devCreds || !devCreds.includes(`:`)) {
    return null;
  }

  const [adminId = ``, token = ``] = devCreds.split(`:`);
  Current.sessionStorage.setItem(`admin_id`, adminId);
  Current.sessionStorage.setItem(`admin_token`, token);
  return { adminId, token };
}

function adminFrom(storage: StorageClient): AdminIds | null {
  const adminId = storage.getItem(`admin_id`);
  const token = storage.getItem(`admin_token`);
  if (adminId && token) {
    return { adminId, token };
  }
  return null;
}
