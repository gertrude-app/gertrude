import type { User } from '../../api/users';
import { GetActivityOverview_counts } from '../../api/users/__generated__/GetActivityOverview';
import { ActivityItem } from '@shared/dashboard/Users/Activity/ReviewDay';

export function user(override: Partial<User> = {}): User {
  return {
    __typename: `User`,
    id: `mock-user-id-${Math.random()}`,
    name: `Huck`,
    screenshotsEnabled: true,
    screenshotsResolution: 1000,
    screenshotsFrequency: 60,
    keyloggingEnabled: true,
    keychains: [],
    devices: [],
    ...override,
  };
}

export function userKeychain(
  override: Partial<User['keychains'][0]> = {},
): User['keychains'][0] {
  return {
    __typename: `Keychain`,
    id: `mock-keychain-id-${Math.random()}`,
    name: `HTC`,
    description: ``,
    isPublic: false,
    authorId: `mock-user-id-${Math.random()}`,
    keys: [],
    ...override,
  };
}

export function activityOverviewCounts(
  numItems = 0,
  numCompleted = 0,
  start = new Date().toISOString(),
): GetActivityOverview_counts {
  return {
    __typename: `MonitoringRangeCounts`,
    dateRange: { __typename: `DateRange`, start },
    numItems,
    numCompleted,
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
