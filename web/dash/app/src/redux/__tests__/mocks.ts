import { v4 as uuid } from 'uuid';
import type {
  User,
  UnlockRequest,
  GetAdmin,
  Device,
  KeychainSummary,
  GetUserActivityDays,
  SuspendFilterRequest,
  GetIdentifiedApps,
} from '@dash/types';
import type { ActivityItem } from '@dash/components';
import * as empty from '../../redux/empty';

type Admin = GetAdmin.Output;

export function adminProfile(override: Partial<Admin> = {}): Admin {
  return {
    id: uuid(),
    email: `you@example.com`,
    subscriptionStatus: `active`,
    notifications: [],
    verifiedNotificationMethods: [],
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
    selectable: true,
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
    ...override,
  };
}

export function adminNotification(
  override: Partial<GetAdmin.Notification> = {},
): GetAdmin.Notification {
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
    keychains: [],
    devices: [],
    createdAt: new Date().toISOString(),
    ...override,
  };
}

export function userDevice(override: Partial<Device> = {}): Device {
  return {
    id: uuid(),
    isOnline: false,
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
    authorId: uuid(),
    numKeys: 0,
    ...override,
  };
}

export function activityDay(
  totalItems = 0,
  numApproved = 0,
  start = new Date().toISOString(),
): GetUserActivityDays.Output['days'][number] {
  return {
    date: start,
    totalItems,
    numApproved,
  };
}

export function keystrokeLine(override: Partial<ActivityItem> = {}): ActivityItem {
  const id = override.id ?? uuid();
  const ids = override.ids ?? [id];
  return {
    id,
    ids,
    appName: `appName-${Math.random()}`,
    line: `line-${Math.random()}`,
    date: new Date().toISOString(),
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
