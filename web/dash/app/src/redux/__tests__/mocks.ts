import type {
  User,
  UnlockRequest,
  GetAdmin,
  Device,
  KeychainSummary,
  GetUserActivityDays,
} from '@dash/types';
import type { ActivityItem } from '@dash/components';
import * as empty from '../../redux/empty';

type Admin = GetAdmin.Output;

export function adminProfile(override: Partial<Admin> = {}): Admin {
  return {
    id: `mock.Admin--id--${Math.random()}`,
    email: `you@example.com`,
    subscriptionStatus: `active`,
    notifications: [],
    verifiedNotificationMethods: [],
    ...override,
  };
}

export function adminNotification(
  override: Partial<GetAdmin.Notification> = {},
): GetAdmin.Notification {
  return {
    id: `mock.AdminNotification--id--${Math.random()}`,
    trigger: `suspendFilterRequestSubmitted`,
    methodId: `mock.AdminVerifiedNotificationMethod--id--${Math.random()}`,
    ...override,
  };
}

export function user(override: Partial<User> = {}): User {
  return {
    id: `mock.User--id--${Math.random()}`,
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
    id: `mock.Device--id--${Math.random()}`,
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
    id: `mock.Keychain--id--${Math.random()}`,
    name: `HTC`,
    description: ``,
    isPublic: false,
    authorId: `mock.Admin--id--${Math.random()}`,
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
  const id = override.id ?? `id-${Math.random()}`;
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
    ...empty.unlockRequest(
      `mock.UnlockRequest--id--${Math.random()}`,
      `mock.User--id--${Math.random()}`,
    ),
    domain: `example.com`,
    appName: `Safari`,
    ...override,
  };
}
