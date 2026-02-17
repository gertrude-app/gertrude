// auto-generated, do not edit
export type { ServerPqlError } from '../PqlError';

export interface AdminKeychain {
  summary: KeychainSummary;
  children: UUID[];
  keys: Key[];
}

export interface AdminNotification {
  id: UUID;
  trigger: AdminNotificationTrigger;
  methodId: UUID;
}

export type AdminNotificationTrigger =
  | `unlockRequestSubmitted`
  | `suspendFilterRequestSubmitted`
  | `securityEventsAll`
  | `securityEventsMedium`
  | `securityEventsRecommended`;

export type AppScope =
  | { type: `unrestricted` }
  | { type: `webBrowsers` }
  | { type: `single`; single: SingleAppScope };

export interface BlockedApp {
  id: UUID;
  identifier: string;
  schedule?: RuleSchedule;
}

export type BlockRule =
  | { case: `bundleIdContains`; value: string }
  | { case: `urlContains`; value: string }
  | { case: `hostnameContains`; value: string }
  | { case: `hostnameEquals`; value: string }
  | { case: `hostnameEndsWith`; value: string }
  | { case: `targetContains`; value: string }
  | { case: `flowTypeIs`; value: `browser` | `socket` }
  | { case: `both`; a: BlockRule; b: BlockRule }
  | { case: `unless`; rule: BlockRule; negatedBy: BlockRule[] };

export interface Child {
  id: UUID;
  name: string;
  keyloggingEnabled: boolean;
  screenshotsEnabled: boolean;
  screenshotsResolution: number;
  screenshotsFrequency: number;
  showSuspensionActivity: boolean;
  keychains: UserKeychainSummary[];
  downtime?: PlainTimeWindow;
  computers: ChildComputer[];
  iosDevices: ChildIOSDevice[];
  blockedApps?: BlockedApp[];
  createdAt: ISODateString;
}

export interface ChildComputer {
  id: UUID;
  computerId: UUID;
  status: ChildComputerStatus;
  modelFamily: DeviceModelFamily;
  modelTitle: string;
  modelIdentifier: string;
  customName?: string;
}

export type ChildComputerStatus =
  | { case: `filterSuspended`; resuming?: ISODateString }
  | { case: `downtime`; ending?: ISODateString }
  | { case: `downtimePaused`; resuming?: ISODateString }
  | { case: `offline` }
  | { case: `filterOff` }
  | { case: `filterOn` };

export interface ChildIOSDevice {
  id: UUID;
  modelName: string;
  deviceType: string;
  iosVersion: string;
  pendingClaimCode?: number;
}

export type ClientAuth = `none` | `child` | `parent` | `superAdmin`;

export interface Device {
  id: UUID;
  name?: string;
  releaseChannel: ReleaseChannel;
  users: Array<{ id: UUID; name: string; status: ChildComputerStatus }>;
  appVersion: string;
  serialNumber: string;
  modelIdentifier: string;
  modelFamily: DeviceModelFamily;
  modelTitle: string;
}

export type DeviceModelFamily =
  | `macBook`
  | `macBookAir`
  | `macBookPro`
  | `mini`
  | `iMac`
  | `studio`
  | `pro`
  | `unknown`;

export interface Key {
  id: UUID;
  keychainId: UUID;
  comment?: string;
  expiration?: ISODateString;
  key: SharedKey;
}

export interface KeychainSummary {
  id: UUID;
  parentId: UUID;
  name: string;
  description?: string;
  warning?: string;
  isPublic: boolean;
  numKeys: number;
}

export interface PlainTime {
  hour: number;
  minute: number;
}

export interface PlainTimeWindow {
  start: PlainTime;
  end: PlainTime;
}

export type Plan =
  | {
      case: `free`;
      kind:
        | { case: `lapsedLight`; stripeId: string; hasTrialedFull: boolean }
        | { case: `lapsedFull`; stripeId?: string }
        | { case: `standard` };
    }
  | {
      case: `light`;
      status:
        | { case: `paid`; stripeId: string; hasTrialedFull: boolean }
        | { case: `overdue`; stripeId: string; hasTrialedFull: boolean };
    }
  | {
      case: `full`;
      status:
        | {
            case: `trialing`;
            kind: { case: `fromLight`; stripeId: string } | { case: `full` };
            until: ISODateString;
          }
        | {
            case: `trialExpired`;
            kind: { case: `fromLight`; stripeId: string } | { case: `full` };
          }
        | { case: `paid`; stripeId: string; monthlyPriceInCents: number }
        | { case: `overdue`; stripeId: string; monthlyPriceInCents: number }
        | { case: `complimentary` };
    };

export type ReleaseChannel = `stable` | `beta` | `canary`;

export type RequestStatus = `pending` | `accepted` | `rejected`;

export interface RuleSchedule {
  mode: `active` | `inactive`;
  days: {
    sunday: boolean;
    monday: boolean;
    tuesday: boolean;
    wednesday: boolean;
    thursday: boolean;
    friday: boolean;
    saturday: boolean;
  };
  window: PlainTimeWindow;
}

export type SecurityEventSeverity = `all` | `medium` | `recommended`;

export type SharedKey =
  | { type: `anySubdomain`; domain: string; scope: AppScope }
  | { type: `domain`; domain: string; scope: AppScope }
  | { type: `domainRegex`; pattern: string; scope: AppScope }
  | { type: `skeleton`; scope: SingleAppScope }
  | { type: `ipAddress`; ipAddress: string; scope: AppScope }
  | { type: `path`; path: string; scope: AppScope };

export type SingleAppScope =
  | { type: `bundleId`; bundleId: string }
  | { type: `identifiedAppSlug`; identifiedAppSlug: string };

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

export type UserActivityItem =
  | {
      case: `screenshot`;
      id: UUID;
      ids: UUID[];
      url: string;
      width: number;
      height: number;
      duringSuspension: boolean;
      flagged: boolean;
      createdAt: ISODateString;
      deletedAt?: ISODateString;
    }
  | {
      case: `keystrokeLine`;
      id: UUID;
      ids: UUID[];
      appName: string;
      line: string;
      duringSuspension: boolean;
      flagged: boolean;
      createdAt: ISODateString;
      deletedAt?: ISODateString;
    };

export interface UserKeychainSummary {
  id: UUID;
  parentId: UUID;
  name: string;
  description?: string;
  isPublic: boolean;
  numKeys: number;
  schedule?: RuleSchedule;
}

export interface VerifiedNotificationMethod {
  id: UUID;
  config:
    | { case: `slack`; channelId: string; channelName: string; token: string }
    | { case: `email`; email: string }
    | { case: `text`; phoneNumber: string };
}

export type WebPolicy =
  | `allowAll`
  | `blockAdult`
  | `blockAdultAnd`
  | `blockAllExcept`
  | `blockAll`;
