import DashboardClient, { type T } from '@shared/pairql/dashboard';

export interface VerificationConfig {
  apiEndpoint?: string;
  dashboardUrl?: string;
  adminToken?: string;
}

export interface VerificationClient {
  getPodcastsClaimData(code: number): Promise<T.GetAmClaimData.Output>;
}

function env(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

export function makeVerificationClient(
  config: VerificationConfig = {},
): VerificationClient {
  const endpoint = config.apiEndpoint ?? env(`API_ENDPOINT`);
  const dashboardUrl = config.dashboardUrl ?? env(`DASH_URL`);
  const adminToken = config.adminToken ?? process.env.ORACLE_ADMIN_TOKEN ?? ``;

  const client = new DashboardClient(endpoint, (init) => {
    const headers = init.headers as Record<string, string>;
    headers[`X-DashboardUrl`] = dashboardUrl;
    headers[`X-AdminToken`] = adminToken;
    return null;
  });

  return {
    async getPodcastsClaimData(code) {
      const result = await client.getAmClaimData({ code });
      return result.valueOrThrow();
    },
  };
}
