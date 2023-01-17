// auto-generated, do not edit

export interface AdminKeychain {
  summary: KeychainSummary;
  keys: Array<Key>;
}

export type AdminNotificationTrigger =
  | 'unlockRequestSubmitted'
  | 'suspendFilterRequestSubmitted';

export type AdminSubscriptionStatus =
  | 'pendingEmailVerification'
  | 'emailVerified'
  | 'signupCanceled'
  | 'complimentary'
  | 'incomplete'
  | 'incompleteExpired'
  | 'trialing'
  | 'active'
  | 'pastDue'
  | 'canceled'
  | 'unpaid';

export type AppScope =
  | { type: 'unrestricted' }
  | { type: 'webBrowsers' }
  | { type: 'single'; single: SingleAppScope };

export type ClientAuth = 'none' | 'user' | 'admin';

export interface Device {
  id: UUID;
  isOnline: boolean;
  modelFamily: DeviceModelFamily;
  modelTitle: string;
}

export type DeviceModelFamily =
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
  dashboardTag?: 'magicLinkTokenNotFound' | 'slackVerificationFailed';
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
  requestProtocol?: string;
  createdAt: ISODateString;
}

export interface User {
  id: UUID;
  name: string;
  keyloggingEnabled: boolean;
  screenshotsEnabled: boolean;
  screenshotsResolution: number;
  screenshotsFrequency: number;
  keychains: Array<KeychainSummary>;
  devices: Array<Device>;
  createdAt: ISODateString;
}
