import AdminClient from '@shared/pairql/admin';
import type { PqlError } from '@shared/pairql';
import type { ClientAuth } from '@shared/pairql/src/admin';

function getEndpoint(): string {
  const href =
    typeof window !== `undefined` ? window.location.href : `http://localhost:4243`;
  if (
    href.includes(`vercel.app`) ||
    href.startsWith(`https://deploy-preview-`) ||
    (href.startsWith(`https://`) && href.includes(`--staging`))
  ) {
    return `https://api--staging.gertrude.app`;
  } else if (href.startsWith(`http://`)) {
    return `http://127.0.0.1:8080`;
  } else {
    return `https://api.gertrude.app`;
  }
}

function createPrepareRequest(): (
  init: RequestInit,
  auth: ClientAuth,
) => PqlError | null {
  return (init: RequestInit, auth: ClientAuth): PqlError | null => {
    const headers = init.headers as Record<string, string>;

    if (auth === `superAdmin`) {
      const token = localStorage.getItem(`admin_token`);
      if (!token) {
        return {
          isPqlError: true,
          id: `b2c3d4e5`,
          type: `loggedOut`,
          debugMessage: `No admin_token found in localStorage`,
        };
      }
      headers[`X-SuperAdminToken`] = token;
    }

    return null;
  };
}

const client = new AdminClient(getEndpoint(), createPrepareRequest());

export default client;
export type { PqlError };
