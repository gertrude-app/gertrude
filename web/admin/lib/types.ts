export type UUID = string;
export type ISODateString = string;
export type TimespanOption = `week` | `month` | `3 months` | `6 months` | `year`;

export interface Installation {
  userId: number;
  appVersion: string; // semver
  filterVersion: string; // semver
  modelIdentifier: string;
  appReleaseChannel: `stable` | `beta` | `canary`;
  osVersionNumber?: string;
  osVersionName?: string;
  createdAt: ISODateString;
}

export interface Child {
  name: string;
  keyloggingEnabled: boolean;
  screenshotsEnabled: boolean;
  numKeychains: number;
  numKeys: number;
  numActivityItems: number;
  installations: Installation[];
  createdAt: ISODateString;
}

export interface AdminData {
  id: UUID;
  hasGclid: boolean;
  abTestVariant?: string;
  email: string;
  subscriptionId?: string; // could theoretically link to stripe dashboard
  monthlyPriceInDollars: number;
  subscriptionStatus:
    | `pendingEmailVerification`
    | `trialing`
    | `trialExpiringSoon`
    | `overdue`
    | `paid`
    | `unpaid`
    | `pendingAccountDeletion`
    | `complimentary`;
  numNotifications: number;
  numKeychains: number;
  children: Child[];
  createdAt: ISODateString;
}
