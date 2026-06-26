const ACCOUNT_ID_KEY = `account_id`;
const ACCOUNT_TOKEN_KEY = `account_token`;

export function getToken(): string | null {
  return localStorage.getItem(ACCOUNT_TOKEN_KEY);
}

export function getAccountId(): string | null {
  return localStorage.getItem(ACCOUNT_ID_KEY);
}

export function isAuthed(): boolean {
  return getToken() !== null;
}

export function setAuth(accountId: UUID, token: UUID): void {
  localStorage.setItem(ACCOUNT_ID_KEY, accountId);
  localStorage.setItem(ACCOUNT_TOKEN_KEY, token);
}

export function clearAuth(): void {
  localStorage.removeItem(ACCOUNT_ID_KEY);
  localStorage.removeItem(ACCOUNT_TOKEN_KEY);
}
