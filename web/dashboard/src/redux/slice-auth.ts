import { createSlice } from '@reduxjs/toolkit';
import Current from '../environment';
import { OptionalVar as Optional } from '../environment/Environment';
import { StorageClient } from '../environment/Storage';

export interface Admin {
  id: UUID;
  token: UUID;
}

export interface AuthState {
  admin: Admin | null;
}

const initialState: AuthState = {
  admin: getInitialAdmin(),
};

export const slice = createSlice({
  name: `auth`,
  initialState,
  reducers: {
    logoutClicked: (state) => {
      state.admin = null;
    },
  },
});

export const { logoutClicked } = slice.actions;

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
