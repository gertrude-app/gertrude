import type {
  BlockRule,
  PersonRelationship,
  SharedKey,
} from '@shared/pairql/src/account';
import type { LucideIcon } from 'lucide-react';
import type React from 'react';

export type { BlockRule, PersonRelationship, SharedKey };

export type LoadableState<Data> =
  | { status: `loading` }
  | { status: `error`; message: string; onRetry: () => void }
  | { status: `success`; data: Data };

export type Device =
  | {
      id: string;
      personId: string;
      type: `mac`;
      name?: string;
      macOSVersion?: string;
      modelName: string;
      modelIdentifier: string;
      online: boolean;
    }
  | {
      id: string;
      personId: string;
      type: `iphone` | `ipad`;
      iOSVersion: string;
      modelName: string;
      modelIdentifier: string;
    };

export type PersonCardPerson = {
  id: string;
  name: string;
  relationship: PersonRelationship;
  devices: Device[];
  screenshot: {
    url: string;
    recency: string;
  } | null;
};

export type SecurityEvent = {
  id: string;
  title: string;
  detail?: string;
  explanation: string;
  createdAt: Date;
  severity: `high` | `medium` | `low`;
} & (
  | {
      type: `mac-app`;
      personId: string;
      personName: string;
      deviceId: string;
      deviceName: string;
    }
  | {
      type: `account`;
      ipAddress?: string;
    }
);

export type UnlockRequest = {
  id: string;
  personName: string;
  domains: string[];
  reason?: string;
  reviewHref?: string;
};

export type SuspensionRequest = {
  id: string;
  personId: string;
  personName: string;
  deviceName?: string;
  requestedDurationInSeconds: number;
  duration: string;
  reason?: string;
  extraMonitoringOptions: Record<string, string>;
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

export type Keychain = {
  id: string;
  name: string;
  description?: string;
  warning?: string;
  numKeys: number;
  isPublic: boolean;
};

export type AccountKeychain = Keychain & {
  assignedPersonIds: string[];
};

export type KeychainKey = {
  id: string;
  key: SharedKey;
  comment?: string;
  expiration?: string;
  appName?: string;
};

export type KeychainDetail = Pick<
  Keychain,
  `id` | `name` | `description` | `isPublic`
> & {
  warning?: string;
  keys: KeychainKey[];
};

export type AssignablePerson = {
  id: string;
  name: string;
};

export type KeychainsPageData = {
  keychains: AccountKeychain[];
  people: AssignablePerson[];
};

export type CustomAlwaysBlockedRule = {
  id: string;
  rule: BlockRule;
  comment?: string;
};

export type InstalledMacApp = {
  id: string;
  personId?: string;
  name: string;
  bundleId: string;
  appIconUrl: string;
};

export type AllowedAlbum = {
  title: string;
  artist: string;
  artworkUrl: string;
  showAlbumArt: boolean;
};

export type NotificationMethod = {
  id: string;
} & (
  | {
      type: `email`;
      emailAddress: string;
    }
  | {
      type: `text`;
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
    }
);

export type NotificationTrigger =
  | `unlockRequestSubmitted`
  | `suspendFilterRequestSubmitted`
  | `securityEventsAll`
  | `securityEventsMedium`
  | `securityEventsRecommended`;

export type Notification = {
  id: string;
  methodId: string;
  trigger: NotificationTrigger;
  enabled: boolean;
  method: NotificationMethod;
};

export type PersonIosSettingsConfiguration = {
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
  allowedAlbums: AllowedAlbum[];
};

export type BlockGroupState = {
  id: string;
  title: string;
  shortDescription: string;
  longExplanation: string;
  blocked: boolean;
};

export type KeyAddressType = `standard` | `strict` | `ipAddress` | `regExp`;

export type KeyScopeType = `allApps` | `webBrowsers` | `singleApp`;

export type UnlockKey = {
  domain: string;
  addressType: KeyAddressType;
  scope: {
    type: KeyScopeType;
    bundleId?: string;
  };
  expiration?: Date;
  note?: string;
};

export type UnlockRequestKeyDraft = {
  id: string;
  allowed: boolean;
  key: UnlockKey;
  moreOptionsExpanded: boolean;
  keychainId: string;
};

export type ButtonLink = {
  text: string;
  href: string;
  variant?: `ghost` | `default`;
  icon?: LucideIcon;
  iconPosition?: `left` | `right`;
};

export type CreationFlowStep = {
  element: React.ReactNode;
  title: string;
  nextEnabled: boolean;
};
