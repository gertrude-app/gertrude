import { Client, type PqlError } from '@shared/pairql';
import type { Result } from '@shared/pairql';

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

type Auth = `superAdmin` | `none`;

function createPrepareRequest(): (init: RequestInit, auth: Auth) => PqlError | null {
  return (init: RequestInit, auth: Auth): PqlError | null => {
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

class AdminClient extends Client<Auth> {
  constructor(
    endpoint: string,
    prepareRequest: (init: RequestInit, auth: Auth) => PqlError | null,
  ) {
    super(endpoint, `admin`, prepareRequest);
  }

  async requestMagicLink(input: {
    email: string;
  }): Promise<Result<{ success: boolean }>> {
    return this.query<{ success: boolean }>(input, `RequestAdminMagicLink`, `none`);
  }

  async verifyMagicLink(input: { token: string }): Promise<Result<{ token: string }>> {
    return this.query<{ token: string }>(input, `VerifyAdminMagicLink`, `none`);
  }

  async macOverview(): Promise<Result<MacOverviewOutput>> {
    return this.query<MacOverviewOutput>(undefined, `MacOverview`, `superAdmin`);
  }

  async iOSOverview(): Promise<Result<IOSOverviewOutput>> {
    return this.query<IOSOverviewOutput>(undefined, `IOSOverview`, `superAdmin`);
  }

  async podcastOverview(): Promise<Result<PodcastOverviewOutput>> {
    return this.query<PodcastOverviewOutput>(undefined, `PodcastOverview`, `superAdmin`);
  }

  async parentsList(input: {
    page: number;
    pageSize?: number;
  }): Promise<Result<ParentsListOutput>> {
    return this.query<ParentsListOutput>(input, `ParentsList`, `superAdmin`);
  }

  async parentDetail(input: { id: string }): Promise<Result<ParentDetailOutput>> {
    return this.query<ParentDetailOutput>(input, `ParentDetail`, `superAdmin`);
  }
}

export interface MacOverviewOutput {
  annualRevenue: number;
  payingParents: number;
  activeParents: number;
  childrenOfActiveParents: number;
  allTimeChildren: number;
  allTimeAppInstallations: number;
  recentSignups: Array<{
    date: string;
    status: string;
    email: string;
  }>;
}

export interface IOSOverviewOutput {
  firstLaunches: number;
  authorizationSuccesses: number;
  filterInstallSuccesses: number;
  conversionRate: number;
}

export interface PodcastOverviewOutput {
  totalInstalls: number;
  successfulSubscriptions: number;
}

export interface ParentsListOutput {
  parents: Array<{
    id: string;
    email: string;
    createdAt: string;
    subscriptionStatus: string;
    numChildren: number;
    numKeychains: number;
    numNotifications: number;
    status: string;
  }>;
  totalCount: number;
  page: number;
  totalPages: number;
}

export interface ParentDetailOutput {
  id: string;
  email: string;
  subscriptionStatus: string;
  subscriptionId?: string;
  monthlyPriceInCents: number;
  createdAt: string;
  children: Array<{
    id: string;
    name: string;
    keyloggingEnabled: boolean;
    screenshotsEnabled: boolean;
    createdAt: string;
    installations: Array<{
      id: string;
      appVersion: string;
      filterVersion?: string;
      osVersion?: string;
      modelIdentifier: string;
      modelFamily: string;
      modelTitle: string;
      createdAt: string;
    }>;
  }>;
  keychains: Array<{
    id: string;
    name: string;
    numKeys: number;
    isPublic: boolean;
  }>;
  notifications: Array<{
    id: string;
    trigger: string;
  }>;
}

const client = new AdminClient(getEndpoint(), createPrepareRequest());

export default client;
export type { PqlError };
