import type {
  BlockRule,
  GetPersonMacSettings,
  PersonRelationship,
  SharedKey,
} from '@shared/pairql/src/account';
import type { LucideIcon } from 'lucide-react';
import type React from 'react';

export type { BlockRule, PersonRelationship, SharedKey };

type MacSettings = GetPersonMacSettings.Output;

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

export type TimeOfDay = NonNullable<
  MacSettings[`internetFiltering`][`downtime`]
>[`start`];

export type Schedule = NonNullable<
  MacSettings[`internetFiltering`][`keychains`][number][`schedule`]
>;

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
  apps: Array<{
    name: string;
    slug: string;
    bundleId?: string;
    appIconUrl?: string;
  }>;
};

export type AssignablePerson = {
  id: string;
  name: string;
};

export type KeychainsPageData = {
  keychains: AccountKeychain[];
  people: AssignablePerson[];
};

export type CustomAlwaysBlockedRule =
  MacSettings[`internetFiltering`][`customAlwaysBlockedRules`][number];

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
