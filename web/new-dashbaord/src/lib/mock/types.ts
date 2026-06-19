export type Device =
  | {
      id: string;
      personId: string;
      type: `mac`;
      name?: string;
      macOSVersion: string;
      modelName: string;
      online: boolean;
    }
  | {
      id: string;
      personId: string;
      type: `iphone` | `ipad`;
      iOSVersion: string;
      modelName: string;
    };

export type Person = {
  id: string;
  name: string;
  screenshot: Screenshot | null;
  musicListening: RecentMusicListening | null;
  podcastListening: RecentPodcastListening | null;
};

export type PersonWithDevices = Person & {
  devices: Device[];
};

export type RecentMusicListening = {
  trackName: string;
  artistName: string;
  albumArtUrl: string;
  recencyInMinutes: number;
};

export type RecentPodcastListening = {
  title: string;
  podcastName: string;
  artworkUrl: string;
  recencyInMinutes: number;
};

export type Screenshot = {
  url: string;
  recency: string;
};

export type ActivityRecord = {
  id: string;
  personId: string;
  duringSuspension: boolean;
  date: Date;
  flagged: boolean;
  deleted: boolean;
} & (
  | { type: `screenshot`; url: string }
  | { type: `keylog`; text: string; applicationName: string }
);

export type ActivityItem = ActivityRecord & {
  personName: string;
};

export type UnlockRequestRecord = {
  id: string;
  personId: string;
  domains: string[];
  reason?: string;
};

export type UnlockRequest = UnlockRequestRecord & {
  personName: string;
};

export type SuspensionRequestRecord = {
  id: string;
  personId: string;
  duration: string;
  reason?: string;
};

export type SuspensionRequest = SuspensionRequestRecord & {
  personName: string;
};

export type SecurityEvent = {
  id: string;
  title: string;
  subtitle?: string;
  explanation: string;
  time: string;
  date: string;
  severity: `high` | `medium` | `low`;
} & (
  | {
      type: `mac-app`;
      personName: string;
      deviceName: string;
    }
  | {
      type: `admin-dashbaord`;
      ipAddress: string;
    }
);

export type Keychain = {
  id: string;
  name: string;
  description?: string;
  numKeys: number;
  isPublic: boolean;
};

export type InstalledMacApp = {
  id: string;
  personId: string;
  name: string;
  bundleId: string;
  appIconUrl: string;
};

export type Key = {
  domain: string;
  addressType: `standard` | `strict` | `ipAddress` | `regExp`;
  scope:
    | {
        type: `allApps`;
      }
    | {
        type: `webBrowsers`;
      }
    | {
        type: `singleApp`;
        bundleId: string;
      };
  expiration?: Date;
  note?: string;
};

export type NotificationMethod =
  | {
      type: `email`;
      emailAddress: string;
    }
  | {
      type: `sms`;
      phoneNumber: string;
    }
  | {
      type: `slack`;
      channelName: string;
      channelId: string;
      botToken: string;
    }
  | {
      type: `ntfy`;
      topicId: string;
    }
  | {
      type: `push`;
    };

export type PersonMacSettingsConfiguration = {
  keyloggingEnabled: boolean;
  screenshots?: {
    resolution: number;
    frequency: number;
  };
  emphasizeSuspensionActivity: boolean;

  downtime?: {
    start: TimeOfDay;
    end: TimeOfDay;
  };
  filteringOn: boolean;
  keychainIds: string[];
  keychainSchedules?: Record<string, Schedule | undefined>;

  alwaysBlockedGroups: {
    adultContent: boolean;
    messagesGifSearch: boolean;
    socialMedia: boolean;
    spotlightSearch: boolean;
  };
  customAlwaysBlockedDomains: string[];

  blockedApps: Array<{
    nameOrBundleId: string;
    appIconUrl: string;
    schedule?: Schedule;
  }>;
  unrestrictedApps: Array<{
    nameOrBundleId: string;
    appIconUrl: string;
  }>;
};

export type PersonMacSettingsRecord = PersonMacSettingsConfiguration & {
  personId: string;
};

export type PersonIosSettingsConfiguration = {
  // blocker
  blockedGroups: {
    appleMusic: boolean;
    whatsApp: boolean;
    musicRecognition: boolean;
    gifs: boolean;
    appleMapsImages: boolean;
    aiFeatures: boolean;
    appStoreImages: boolean;
    spotlight: boolean;
    ads: boolean;
    appleDotCom: boolean;
    spotifyImages: boolean;
  };
  preventProtectionRemoval: boolean;
  allowDeletingApps: boolean;
  allowFactoryReset: boolean;
  allowInstallingApps: boolean;

  // music
  allowedAlbums: Array<{
    title: string;
    artist: string;
    artworkUrl: string;
    showAlbumArt: boolean;
  }>;
};

export type PersonIosSettingsRecord = PersonIosSettingsConfiguration & {
  personId: string;
};

export type TimeOfDay = {
  hour: number;
  minute: number;
};

export type Schedule = {
  type: `active` | `inactive`;
  days: {
    sunday: boolean;
    monday: boolean;
    tuesday: boolean;
    wednesday: boolean;
    thursday: boolean;
    friday: boolean;
    saturday: boolean;
  };
  startTime: TimeOfDay;
  endTime: TimeOfDay;
};

export type MockDb = {
  people: Person[];
  devices: Device[];
  activity: ActivityRecord[];
  unlockRequests: UnlockRequestRecord[];
  suspensionRequests: SuspensionRequestRecord[];
  securityEvents: SecurityEvent[];
  keychains: Keychain[];
  macSettings: PersonMacSettingsRecord[];
  iosSettings: PersonIosSettingsRecord[];
  installedMacApps: InstalledMacApp[];
};
