export interface SuccessOutput {
  success: boolean;
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

export type AppScope =
  | { type: 'unrestricted' }
  | { type: 'webBrowsers' }
  | { type: 'single'; single: SingleAppScope };

export type SharedKey =
  | { type: 'anySubdomain'; domain: string; scope: AppScope }
  | { type: 'domain'; domain: string; scope: AppScope }
  | { type: 'domainRegex'; pattern: string; scope: AppScope }
  | { type: 'skeleton'; pattern: string; scope: SingleAppScope }
  | { type: 'ipAddress'; ipAddress: string; scope: AppScope }
  | { type: 'path'; path: string; scope: AppScope };

export enum ClientAuth {
  none,
  user,
  admin,
}

export type SingleAppScope =
  | { type: 'bundleId'; bundleId: string }
  | { type: 'identifiedAppSlug'; identifiedAppSlug: string };

export enum AdminNotificationTrigger {
  unlockRequestSubmitted,
  suspendFilterRequestSubmitted,
}

export enum RequestStatus {
  pending,
  accepted,
  rejected,
}
