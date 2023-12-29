// auto-generated, do not edit

export interface AdminKeychain {
  summary: KeychainSummary;
  keys: Key[];
}

export interface AdminNotification {
  id: UUID;
  trigger: AdminNotificationTrigger;
  methodId: UUID;
}

export type AdminNotificationTrigger =
  | 'unlockRequestSubmitted'
  | 'suspendFilterRequestSubmitted';

export type AdminSubscriptionStatus =
  | { case: 'trialing'; daysLeft: number }
  | { case: 'complimentary' }
  | { case: 'paid' }
  | { case: 'overdue' }
  | { case: 'unpaid' };

export type AppScope =
  | { type: 'unrestricted' }
  | { type: 'webBrowsers' }
  | { type: 'single'; single: SingleAppScope };

export type ClientAuth = 'none' | 'user' | 'admin' | 'superAdmin';

export interface Device {
  id: UUID;
  name?: string;
  releaseChannel: ReleaseChannel;
  users: Array<{ id: UUID; name: string; isOnline: boolean }>;
  appVersion: string;
  serialNumber: string;
  modelIdentifier: string;
  modelFamily: DeviceModelFamily;
  modelTitle: string;
}

export type DeviceModelFamily =
  | 'macBook'
  | 'macBookAir'
  | 'macBookPro'
  | 'mini'
  | 'iMac'
  | 'studio'
  | 'pro'
  | 'unknown';

export interface Key {
  id: UUID;
  keychainId: UUID;
  comment?: string;
  expiration?: ISODateString;
  key: SharedKey;
}

export interface KeychainSummary {
  id: UUID;
  authorId: UUID;
  name: string;
  description?: string;
  isPublic: boolean;
  numKeys: number;
}

export type ReleaseChannel = 'stable' | 'beta' | 'canary';

export type RequestStatus = 'pending' | 'accepted' | 'rejected';

export interface ServerPqlError {
  version: number;
  id: string;
  requestId: string;
  type: 'notFound' | 'badRequest' | 'serverError' | 'unauthorized' | 'loggedOut';
  userMessage?: string;
  userAction?: string;
  debugMessage: string;
  entityName?: string;
  showContactSupport: boolean;
  dashboardTag?:
    | 'magicLinkTokenNotFound'
    | 'slackVerificationFailed'
    | 'emailAlreadyVerified';
  appTag?: 'userTokenNotFound' | 'connectionCodeNotFound';
  statusCode: number;
}

export type SharedKey =
  | { type: 'anySubdomain'; domain: string; scope: AppScope }
  | { type: 'domain'; domain: string; scope: AppScope }
  | { type: 'domainRegex'; pattern: string; scope: AppScope }
  | { type: 'skeleton'; scope: SingleAppScope }
  | { type: 'ipAddress'; ipAddress: string; scope: AppScope }
  | { type: 'path'; path: string; scope: AppScope };

export type SingleAppScope =
  | { type: 'bundleId'; bundleId: string }
  | { type: 'identifiedAppSlug'; identifiedAppSlug: string };

export interface SuccessOutput {
  success: boolean;
}

export interface SuspendFilterRequest {
  id: UUID;
  deviceId: UUID;
  status: RequestStatus;
  userName: string;
  requestedDurationInSeconds: number;
  requestComment?: string;
  responseComment?: string;
  extraMonitoringOptions: { [key: string]: string };
  createdAt: ISODateString;
}

export interface UnlockRequest {
  id: UUID;
  userId: UUID;
  userName: string;
  status: RequestStatus;
  url?: string;
  domain?: string;
  ipAddress?: string;
  requestComment?: string;
  appName?: string;
  appSlug?: string;
  appBundleId?: string;
  appCategories: string[];
  createdAt: ISODateString;
}

export interface User {
  id: UUID;
  name: string;
  keyloggingEnabled: boolean;
  screenshotsEnabled: boolean;
  screenshotsResolution: number;
  screenshotsFrequency: number;
  showSuspensionActivity: boolean;
  keychains: KeychainSummary[];
  devices: UserDevice[];
  createdAt: ISODateString;
}

export type UserActivityItem =
  | {
      case: 'screenshot';
      id: UUID;
      ids: UUID[];
      url: string;
      width: number;
      height: number;
      duringSuspension: boolean;
      createdAt: ISODateString;
      deletedAt?: ISODateString;
    }
  | {
      case: 'keystrokeLine';
      id: UUID;
      ids: UUID[];
      appName: string;
      line: string;
      duringSuspension: boolean;
      createdAt: ISODateString;
      deletedAt?: ISODateString;
    };

export interface UserDevice {
  id: UUID;
  isOnline: boolean;
  modelFamily: DeviceModelFamily;
  modelTitle: string;
  modelIdentifier: string;
  customName?: string;
}

export interface VerifiedNotificationMethod {
  id: UUID;
  config:
    | { case: 'slack'; channelId: string; channelName: string; token: string }
    | { case: 'email'; email: string }
    | { case: 'text'; phoneNumber: string };
}
