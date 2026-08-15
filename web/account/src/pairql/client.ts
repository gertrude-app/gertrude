import AccountClient from '@shared/pairql/account';
import type { PqlError } from '@shared/pairql';
import type { ClientAuth } from '@shared/pairql/src/account';
import { getToken } from './auth';

export const apiEndpoint = getApiEndpoint();

export const liveClient = new AccountClient(apiEndpoint, prepareRequest);

function prepareRequest(init: RequestInit, auth: ClientAuth): PqlError | null {
  const headers = init.headers as Record<string, string>;

  if (!apiEndpoint.startsWith(`https://api.`)) {
    headers[`X-DashboardUrl`] = window.location.origin;
  }

  if (auth === `parent`) {
    const token = getToken();
    if (!token) {
      return {
        isPqlError: true,
        id: `8f2c1d4a`,
        type: `loggedOut`,
        debugMessage: `No account token found`,
      };
    }
    headers[`X-AccountToken`] = token;
  }
  return null;
}

function getApiEndpoint(): string {
  const endpoint = import.meta.env.VITE_API_ENDPOINT;
  if (!endpoint) {
    throw new Error(`VITE_API_ENDPOINT environment variable is not set`);
  }
  return endpoint;
}
