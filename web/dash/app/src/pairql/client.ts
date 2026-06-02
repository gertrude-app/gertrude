import DashboardClient from '@shared/pairql/dashboard';
import type { PqlError } from '@shared/pairql';
import type { ClientAuth } from '@shared/pairql/src/dashboard';

const apiEndpoint = getApiEndpoint();

export const liveClient = new DashboardClient(
  apiEndpoint,
  createPrepareRequest(apiEndpoint),
);

function createPrepareRequest(
  endpoint: string,
): (init: RequestInit, auth: ClientAuth) => PqlError | null {
  return (init: RequestInit, auth: ClientAuth): PqlError | null => {
    const headers = init.headers as Record<string, string>;

    if (!endpoint.startsWith(`https://api.`)) {
      headers[`X-DashboardUrl`] = window.location.origin;
    }

    if (auth === `parent`) {
      const token =
        localStorage.getItem(`admin_token`) ?? sessionStorage.getItem(`admin_token`);
      if (!token) {
        return {
          isPqlError: true,
          id: `10569a9f`,
          type: `loggedOut`,
          debugMessage: `No parent token found`,
        };
      }
      headers[`X-AdminToken`] = token;
    }

    return null;
  };
}

function getApiEndpoint(): string {
  const endpoint = import.meta.env.VITE_API_ENDPOINT;
  if (!endpoint) {
    throw new Error(`VITE_API_ENDPOINT environment variable is not set`);
  }
  return endpoint;
}

export type ApiClient = Omit<
  typeof liveClient,
  `endpoint` | `domain` | `prepareRequest` | `query`
>;
