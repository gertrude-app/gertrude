// auto-generated, do not edit

export enum AdminNotificationTrigger {
  unlockRequestSubmitted,
  suspendFilterRequestSubmitted,
}

export type AppScope =
  | { type: 'unrestricted' }
  | { type: 'webBrowsers' }
  | { type: 'single'; single: SingleAppScope };

export enum ClientAuth {
  none,
  user,
  admin,
}

export enum DeviceModelFamily {
  macBookAir,
  macBookPro,
  mini,
  iMac,
  studio,
  pro,
  unknown,
}

export interface Key {
  id: UUID;
  keychainId: UUID;
  comment?: string;
  expiration?: ISODateString;
  key: SharedKey;
}

export interface Keychain {
  id: UUID;
  name: string;
  description?: string;
  isPublic: boolean;
  authorId: UUID;
  keys: Array<Key>;
}

export enum RequestStatus {
  pending,
  accepted,
  rejected,
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
