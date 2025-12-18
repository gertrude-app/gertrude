import { env } from '@shared/components';
import { createContext, useCallback, useContext, useState } from 'react';
import type { StorageClient } from '../environment/Storage';
import Current from '../environment';
import { OptionalVar as Optional } from '../environment/Environment';

type Admin = {
  id: UUID;
  token: UUID;
};

type Auth = {
  admin: Admin | null;
  login(id: UUID, token: UUID): unknown;
  logout(): unknown;
};

const AuthContext = createContext<Auth>({
  admin: null,
  login: () => {},
  logout: () => {},
});

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [admin, setAdmin] = useState<Admin | null>(getInitialAdmin());

  const login = useCallback((id: UUID, token: UUID): void => {
    Current.localStorage.setItem(`admin_id`, id);
    Current.localStorage.setItem(`admin_token`, token);
    Current.localStorage.removeItem(`dev_logged_out`);
    setAdmin({ id, token });
  }, []);

  const logout = useCallback((): void => {
    Current.sessionStorage.removeItem(`admin_id`);
    Current.sessionStorage.removeItem(`admin_token`);
    Current.localStorage.removeItem(`admin_id`);
    Current.localStorage.removeItem(`admin_token`);
    if (!Current.env.isProd()) {
      Current.localStorage.setItem(`dev_logged_out`, `true`);
    }
    setAdmin(null);
  }, []);

  return (
    <AuthContext.Provider value={{ admin, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export function useAuth(): Auth {
  return useContext(AuthContext);
}

function getInitialAdmin(): Admin | null {
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
  return { id: adminId, token };
}

function adminFrom(storage: StorageClient): Admin | null {
  const adminId = storage.getItem(`admin_id`);
  const token = storage.getItem(`admin_token`);
  if (adminId && token) {
    return { id: adminId, token };
  }
  return null;
}
