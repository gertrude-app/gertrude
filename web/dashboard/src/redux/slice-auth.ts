import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import Current from '../environment';
import { OptionalVar as Optional } from '../environment/Environment';
import { StorageClient } from '../environment/Storage';
import { Req } from './helpers';
import { createAsyncThunk } from './hooks';

export interface Admin {
  id: UUID;
  token: UUID;
}

export interface AuthState {
  admin: Admin | null;
  loginEmail: string;
  loginPassword: string;
  loginRequest: RequestState;
}

const initialState: AuthState = {
  admin: getInitialAdmin(),
  loginEmail: ``,
  loginPassword: ``,
  loginRequest: Req.idle(),
};

export const slice = createSlice({
  name: `auth`,
  initialState,
  reducers: {
    loginFormSubmitted: (state) => {
      state.loginRequest = Req.ongoing();
    },
    loginSucceeded: (state, action: PayloadAction<Admin>) => {
      state.admin = action.payload;
      state.loginRequest = Req.succeed(void 0);
      state.loginEmail = ``;
      state.loginPassword = ``;
    },
    loginFailed: (state, action: PayloadAction<ApiError>) => {
      state.loginRequest = Req.fail(action.payload);
    },
    loginErrorExpired: (state) => {
      state.loginRequest = Req.idle();
    },
    loginEmailUpdated: (state, action: PayloadAction<string>) => {
      state.loginEmail = action.payload;
    },
    loginPasswordUpdated: (state, action: PayloadAction<string>) => {
      state.loginPassword = action.payload;
    },
    logoutClicked: (state) => {
      state.admin = null;
    },
  },
});

export const submitLoginForm = createAsyncThunk(
  `${slice.name}/submitLoginForm`,
  async (_, { dispatch, getState }) => {
    dispatch(loginFormSubmitted());
    const { loginEmail, loginPassword } = getState().auth;
    const result = await Current.api.admin.login(loginEmail, loginPassword);
    result.with({
      success: (admin) => dispatch(loginSucceeded(admin)),
      error: (error) => {
        dispatch(loginFailed(error));
        setTimeout(() => dispatch(loginErrorExpired()), 6000);
      },
    });
  },
);

const { loginFormSubmitted, loginFailed, loginErrorExpired } = slice.actions;

export const { logoutClicked, loginSucceeded, loginEmailUpdated, loginPasswordUpdated } =
  slice.actions;

export default slice.reducer;

// helpers

export function getInitialAdmin(): Admin | null {
  if (Current.env.isProd() || Current.sessionStorage.getItem(`dev_logged_out`) !== null) {
    return adminFrom(Current.sessionStorage) ?? adminFrom(Current.localStorage);
  }

  const devCreds = Current.env.optionalVar(Optional.TestAdminCreds);
  if (!devCreds || !devCreds.includes(`:`)) {
    return null;
  }

  const [id = ``, token = ``] = devCreds.split(`:`);
  Current.sessionStorage.setItem(`admin_id`, id);
  Current.sessionStorage.setItem(`admin_token`, token);
  return { id, token };
}

function adminFrom(storage: StorageClient): Admin | null {
  const id = storage.getItem(`admin_id`);
  const token = storage.getItem(`admin_token`);
  if (id && token) {
    return { id, token };
  }
  return null;
}
