import { v4 as uuid } from 'uuid';
import type {
  User,
  UnlockRequest,
  GetAdmin,
  Device,
  KeychainSummary,
  ChildActivitySummaries,
  SuspendFilterRequest,
  GetIdentifiedApps,
  FamilyActivitySummaries,
  AdminNotification,
} from '@dash/types';
import type { ActivityFeedItem } from '@dash/components';
import * as empty from '../../lib/empty';

type Admin = GetAdmin.Output;

export function adminSettings(override: Partial<Admin> = {}): Admin {
  return {
    id: uuid(),
    email: `you@example.com`,
    subscriptionStatus: { case: `paid` },
    notifications: [],
    verifiedNotificationMethods: [],
    hasAdminChild: false,
    monthlyPriceInDollars: 15,
    ...override,
  };
}

export function identifiedApp(
  override: Partial<GetIdentifiedApps.Output[number]> = {},
): GetIdentifiedApps.Output[number] {
  return {
    id: uuid(),
    name: `Brave Browser`,
    slug: `brave`,
    launchable: true,
    bundleIds: [{ id: uuid(), bundleId: `com.brave.Browser` }],
    ...override,
  };
}

export function suspendFilterRequest(
  override: Partial<SuspendFilterRequest>,
): SuspendFilterRequest {
  return {
    id: uuid(),
    deviceId: uuid(),
    status: `pending`,
    userName: `Little Jimmy`,
    requestComment: `I want to watch a video`,
    requestedDurationInSeconds: 120,
    createdAt: new Date().toISOString(),
    extraMonitoringOptions: {},
    ...override,
  };
}

export function adminNotification(
  override: Partial<AdminNotification> = {},
): AdminNotification {
  return {
    id: uuid(),
    trigger: `suspendFilterRequestSubmitted`,
    methodId: uuid(),
    ...override,
  };
}

export function user(override: Partial<User> = {}): User {
  return {
    id: uuid(),
    name: `Huck`,
    screenshotsEnabled: true,
    screenshotsResolution: 1000,
    screenshotsFrequency: 60,
    keyloggingEnabled: true,
    showSuspensionActivity: true,
    keychains: [],
    devices: [
      {
        id: `mac-123`,
        deviceId: `d-mac-123`,
        modelFamily: `macBookAir`,
        modelTitle: `MacBook Air`,
        modelIdentifier: `MacBookAir8,1`,
        status: { case: `filterOn` },
      },
    ],
    createdAt: new Date().toISOString(),
    ...override,
  };
}

export function userDevice(override: Partial<Device> = {}): Device {
  return {
    id: uuid(),
    appVersion: `2.2.0`,
    users: [
      {
        name: `Little Jimmy`,
        id: uuid(),
        status: { case: `filterOn` },
      },
    ],
    modelIdentifier: `MacBookAir8,1`,
    serialNumber: `C02XV0Y0JGH7`,
    releaseChannel: `stable`,
    modelFamily: `macBookAir`,
    modelTitle: `MacBook Air`,
    ...override,
  };
}

export function keychainSummary(
  override: Partial<KeychainSummary> = {},
): KeychainSummary {
  return {
    id: uuid(),
    name: `HTC`,
    description: ``,
    isPublic: false,
    parentId: uuid(),
    numKeys: 0,
    ...override,
  };
}

export function childActivitySummary(
  numTotal = 0,
  numApproved = 0,
  numFlagged = 0,
  start = new Date().toISOString(),
): ChildActivitySummaries.Output[`days`][number] {
  return {
    date: start,
    numTotal,
    numFlagged,
    numApproved,
  };
}

export function familyActivitySummary(
  override: Partial<FamilyActivitySummaries.Output[number]> = {},
): FamilyActivitySummaries.Output[number] {
  return { ...childActivitySummary(1, 1), ...override };
}

type KeystrokeActivityItem = {
  case: `keystrokeLine`;
  id: UUID;
  ids: UUID[];
  appName: string;
  line: string;
  flagged: boolean;
  createdAt: ISODateString;
  deletedAt?: ISODateString;
  duringSuspension: boolean;
};

export function keystrokeActivityItem(
  override: Partial<KeystrokeActivityItem> = {},
): KeystrokeActivityItem {
  const id = override.id ?? uuid();
  return {
    case: `keystrokeLine`,
    id: id,
    ids: [id],
    appName: `appName-${Math.random()}`,
    line: `line-${Math.random()}`,
    createdAt: new Date().toISOString(),
    duringSuspension: false,
    flagged: false,
    ...override,
  };
}

type ScreenshotActivityItem = {
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
};

export function screenshotActivityItem(
  override: Partial<ScreenshotActivityItem> = {},
): ScreenshotActivityItem {
  const id = override.id ?? uuid();
  const width = override.width ?? 600;
  const height = override.height ?? 400;
  return {
    case: `screenshot`,
    id,
    ids: [id],
    url: `https://fakeimg.pl/${width}x${height}/3e2a73/ffffff`,
    width,
    height,
    createdAt: new Date().toISOString(),
    duringSuspension: false,
    flagged: false,
    ...override,
  };
}

export function keystrokeLine(
  override: Partial<ActivityFeedItem> = {},
): ActivityFeedItem {
  const id = override.id ?? uuid();
  const ids = override.ids ?? [id];
  return {
    id,
    ids,
    appName: `appName-${Math.random()}`,
    line: `line-${Math.random()}`,
    date: new Date().toISOString(),
    duringSuspension: false,
    flagged: false,
    ...override,
    type: `KeystrokeLine`,
  };
}

export function unlockRequest(override: Partial<UnlockRequest> = {}): UnlockRequest {
  return {
    ...empty.unlockRequest(uuid(), uuid()),
    userName: `Huck`,
    requestComment: `Please dad!`,
    domain: `example.com`,
    appName: `Brave`,
    appSlug: `brave`,
    appCategories: [`browser`],
    ...override,
  };
}
