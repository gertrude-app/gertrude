import type {
  ActivityItem,
  ActivityRecord,
  Device,
  InstalledMacApp,
  Keychain,
  MockDb,
  Notification,
  Person,
  PersonIosSettingsRecord,
  PersonMacSettingsRecord,
  PersonWithDevices,
  SuspensionRequest,
  SuspensionRequestRecord,
  UnlockRequest,
  UnlockRequestRecord,
} from './types';

const fallbackPersonName = `Child`;

export function getPersonName(db: MockDb, personId: string): string {
  return db.people.find((person) => person.id === personId)?.name ?? fallbackPersonName;
}

function withDevices(db: MockDb, person: Person): PersonWithDevices {
  return {
    ...person,
    devices: db.devices.filter((device) => device.personId === person.id),
  };
}

function withUnlockRequestPersonName(
  db: MockDb,
  request: UnlockRequestRecord,
): UnlockRequest {
  return {
    ...request,
    personName: getPersonName(db, request.personId),
  };
}

function withSuspensionRequestPersonName(
  db: MockDb,
  request: SuspensionRequestRecord,
): SuspensionRequest {
  return {
    ...request,
    personName: getPersonName(db, request.personId),
  };
}

function withActivityPersonName(db: MockDb, activity: ActivityRecord): ActivityItem {
  return {
    ...activity,
    personName: getPersonName(db, activity.personId),
  };
}

function withNotificationMethod(
  db: MockDb,
  notification: MockDb[`notifications`][number],
): Notification | null {
  const method = db.notificationMethods.find(
    (candidate) => candidate.id === notification.methodId,
  );

  return method ? { ...notification, method } : null;
}

export function getPeople(db: MockDb): PersonWithDevices[] {
  return db.people.map((person) => withDevices(db, person));
}

export function getPerson(db: MockDb, personId: string): PersonWithDevices | undefined {
  const person = db.people.find((candidate) => candidate.id === personId);
  return person ? withDevices(db, person) : undefined;
}

export function getUnlockRequests(db: MockDb): UnlockRequest[] {
  return db.unlockRequests.map((request) => withUnlockRequestPersonName(db, request));
}

export function getSuspensionRequests(db: MockDb): SuspensionRequest[] {
  return db.suspensionRequests.map((request) =>
    withSuspensionRequestPersonName(db, request),
  );
}

export function getActivityItems(db: MockDb): ActivityItem[] {
  return db.activity.map((activity) => withActivityPersonName(db, activity));
}

export function getNotifications(db: MockDb): Notification[] {
  return db.notifications
    .map((notification) => withNotificationMethod(db, notification))
    .filter((notification): notification is Notification => notification !== null);
}

export function getAppChrome(db: MockDb): { requestCount: number } {
  return {
    requestCount: db.unlockRequests.length + db.suspensionRequests.length,
  };
}

export function getPeoplePage(db: MockDb): {
  people: PersonWithDevices[];
  unlockRequests: UnlockRequest[];
  suspensionRequests: SuspensionRequest[];
  securityEvents: MockDb[`securityEvents`];
} {
  return {
    people: getPeople(db),
    unlockRequests: getUnlockRequests(db),
    suspensionRequests: getSuspensionRequests(db),
    securityEvents: db.securityEvents,
  };
}

export function getNotificationSettingsPage(db: MockDb): {
  notificationMethods: MockDb[`notificationMethods`];
  notifications: Notification[];
} {
  return {
    notificationMethods: db.notificationMethods,
    notifications: getNotifications(db),
  };
}

export function getPersonSettingsPage(
  db: MockDb,
  personId: string,
): {
  person: PersonWithDevices | undefined;
  personName: string;
} {
  const person = getPerson(db, personId);

  return {
    person,
    personName: person?.name ?? `Person`,
  };
}

export function getPersonMacSettingsPage(
  db: MockDb,
  personId: string,
): {
  personName: string;
  macDevices: Array<Extract<Device, { type: `mac` }>>;
  config: PersonMacSettingsRecord | undefined;
  keychains: Keychain[];
  installedMacApps: InstalledMacApp[];
} {
  const config = db.macSettings.find((settings) => settings.personId === personId);

  return {
    personName: getPersonName(db, personId),
    macDevices: db.devices.filter(
      (device): device is Extract<Device, { type: `mac` }> =>
        device.personId === personId && device.type === `mac`,
    ),
    config,
    keychains:
      config?.keychainIds
        .map((keychainId) => db.keychains.find((keychain) => keychain.id === keychainId))
        .filter((keychain): keychain is Keychain => keychain !== undefined) ?? [],
    installedMacApps: db.installedMacApps.filter((app) => app.personId === personId),
  };
}

export function getPersonIosSettingsPage(
  db: MockDb,
  personId: string,
): {
  personName: string;
  iosDevices: Array<Extract<Device, { type: `iphone` | `ipad` }>>;
  config: PersonIosSettingsRecord | undefined;
} {
  const config = db.iosSettings.find((settings) => settings.personId === personId);

  return {
    personName: getPersonName(db, personId),
    iosDevices: db.devices.filter(
      (device): device is Extract<Device, { type: `iphone` | `ipad` }> =>
        device.personId === personId &&
        (device.type === `iphone` || device.type === `ipad`),
    ),
    config,
  };
}

export function getRequestsPage(db: MockDb): {
  unlockRequestCount: number;
  suspensionRequestCount: number;
} {
  return {
    unlockRequestCount: db.unlockRequests.length,
    suspensionRequestCount: db.suspensionRequests.length,
  };
}

export function getUnlockRequestsPage(db: MockDb): {
  requests: UnlockRequest[];
} {
  return {
    requests: getUnlockRequests(db),
  };
}

export function getSuspensionRequestsPage(db: MockDb): {
  requests: SuspensionRequest[];
} {
  return {
    requests: getSuspensionRequests(db),
  };
}

export function getActivityPage(db: MockDb): {
  activities: ActivityItem[];
} {
  return {
    activities: getActivityItems(db),
  };
}

export function getActivityDayPage(
  db: MockDb,
  dayDate: Date,
): {
  items: ActivityItem[];
} {
  return {
    items: getActivityItems(db).filter(
      (activity) => activity.date.toDateString() === dayDate.toDateString(),
    ),
  };
}

export function getPersonActivityPage(
  db: MockDb,
  personId: string,
): {
  personName: string;
  activities: ActivityItem[];
} {
  return {
    personName: getPersonName(db, personId),
    activities: getActivityItems(db).filter((activity) => activity.personId === personId),
  };
}

export function getPersonActivityDayPage(
  db: MockDb,
  personId: string,
  dayDate: Date,
): {
  personName: string;
  items: ActivityItem[];
} {
  return {
    personName: getPersonName(db, personId),
    items: getActivityItems(db).filter(
      (activity) =>
        activity.personId === personId &&
        activity.date.toDateString() === dayDate.toDateString(),
    ),
  };
}
