/// --- children/devices ---

export type Device =
  | {
      type: 'mac';
      name?: string;
      macOSVersion: string;
      modelName: string;
      online: boolean;
    }
  | {
      type: 'iphone' | 'ipad';
      iOSVersion: string;
      modelName: string;
    };

export type Person = {
  name: string;
  devices: Device[];
  screenshot: Screenshot | null;
  musicListening: RecentMusicListening | null;
  podcastListening: RecentPodcastListening | null;
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
  recency: string; // '3 minutes ago', etc.
};

const familyIpad: Device = {
  type: 'ipad',
  iOSVersion: '18.4',
  modelName: 'iPad (10th generation)',
};

const schoolMacBook: Device = {
  type: 'mac',
  macOSVersion: '15.4',
  modelName: 'MacBook Air 13-inch, M2',
  online: true,
};

const kitchenIMac: Device = {
  type: 'mac',
  name: 'Kitchen iMac',
  macOSVersion: '14.7',
  modelName: 'iMac 24-inch, M1',
  online: false,
};

export const mockChildren: Person[] = [
  {
    name: 'Jimmy',
    devices: [familyIpad, schoolMacBook],
    screenshot: {
      url: '/example-screenshots/kid-school.png',
      recency: '3 minutes ago',
    },
    musicListening: {
      trackName: 'Here Comes the Sun',
      artistName: 'The Beatles',
      albumArtUrl:
        'https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/df/db/61/dfdb615d-47f8-06e9-9533-b96daccc029f/18UMGIM31076.rgb.jpg/300x300bb.jpg',
      recencyInMinutes: 0,
    },
    podcastListening: {
      title: 'How Volcanoes Work',
      podcastName: 'Brains On!',
      artworkUrl:
        'https://is1-ssl.mzstatic.com/image/thumb/Podcasts211/v4/99/e5/39/99e53993-e2ea-70a3-64d6-f2f86ab84e53/mza_8458923780593912977.jpg/300x300bb.jpg',
      recencyInMinutes: 3,
    },
  },
  {
    name: 'Sally',
    devices: [
      {
        type: 'iphone',
        iOSVersion: '18.3',
        modelName: 'iPhone 14',
      },
      familyIpad,
      kitchenIMac,
    ],
    screenshot: null,
    musicListening: {
      trackName: 'Rainbow Connection',
      artistName: 'Kermit the Frog',
      albumArtUrl:
        'https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/0f/d8/15/0fd815cb-45f4-b334-e26d-0ea9875795e3/00050087348533.rgb.jpg/300x300bb.jpg',
      recencyInMinutes: 57,
    },
    podcastListening: null,
  },
  {
    name: 'Franny',
    devices: [],
    screenshot: null,
    musicListening: null,
    podcastListening: null,
  },
  {
    name: 'Theo',
    devices: [
      {
        type: 'ipad',
        iOSVersion: '17.7',
        modelName: 'iPad mini (6th generation)',
      },
    ],
    screenshot: null,
    musicListening: null,
    podcastListening: {
      title: 'The Case of the Missing Moon Rocks',
      podcastName: 'Wow in the World',
      artworkUrl:
        'https://is1-ssl.mzstatic.com/image/thumb/Podcasts211/v4/4c/b0/4a/4cb04a06-4e0a-d534-2a28-3f2fb37fa14e/mza_14610475686329584932.jpeg/300x300bb.jpg',
      recencyInMinutes: 0,
    },
  },
  {
    name: 'Maggie',
    devices: [
      {
        type: 'iphone',
        iOSVersion: '18.4',
        modelName: 'iPhone SE (3rd generation)',
      },
      schoolMacBook,
      kitchenIMac,
    ],
    screenshot: {
      url: '/example-screenshots/minecraft.png',
      recency: '18 minutes ago',
    },
    musicListening: null,
    podcastListening: null,
  },
];

/// --- notifications/methods ---

export type NotificationMethod =
  | {
      type: 'email';
      emailAddress: string;
    }
  | {
      type: 'sms';
      phoneNumber: string;
    }
  | {
      type: 'slack';
      channelName: string;
      channelId: string;
      botToken: string;
    }
  | {
      type: 'ntfy';
      topicId: string;
    }
  | {
      type: 'push';
    };

/// --- security ---

export type SecurityEvent = {
  title: string;
  subtitle?: string;
  explanation: string;
  time: string; // '7:23 AM', etc.
  date: string; // 'May 12, 2026', etc.
  severity: 'high' | 'medium' | 'low';
} & (
  | {
      type: 'mac-app';
      personName: string;
      deviceName: string;
    }
  | {
      type: 'admin-dashbaord';
      ipAddress: string;
    }
);

export const mockSecurityEvents: SecurityEvent[] = [
  {
    type: 'admin-dashbaord',
    title: 'Successful login',
    subtitle: 'Using email and password',
    explanation:
      'This event occurs whenever a parent successfully logs into the parents admin website. Should be investigated if you do not recognize the successful login as your own.',
    ipAddress: '127.0.0.1',
    time: '9:52 AM',
    date: 'May 25, 2026',
    severity: 'low',
  },
  {
    type: 'admin-dashbaord',
    title: 'Successful login',
    subtitle: 'Using email and password',
    explanation:
      'This event occurs whenever a parent successfully logs into the parents admin website. Should be investigated if you do not recognize the successful login as your own.',
    ipAddress: '172.16.4.28',
    time: '10:21 AM',
    date: 'May 18, 2026',
    severity: 'low',
  },
  {
    type: 'mac-app',
    title: 'Filter suspension expired',
    explanation:
      'This event occurs when a filter suspension ends after the scheduled time. It does not represent a safety risk.',
    personName: 'Jimmy',
    deviceName: 'MacBook Air 13-inch, M2',
    time: '7:31 AM',
    date: 'May 15, 2026',
    severity: 'low',
  },
  {
    type: 'admin-dashbaord',
    title: 'Successful login',
    subtitle: 'Using email and password',
    explanation:
      'This event occurs whenever a parent successfully logs into the parents admin website. Should be investigated if you do not recognize the successful login as your own.',
    ipAddress: '10.0.0.42',
    time: '11:33 AM',
    date: 'May 15, 2026',
    severity: 'low',
  },
  {
    type: 'mac-app',
    title: 'Filter suspended remotely',
    subtitle: 'For 11 hrs',
    explanation:
      'This event occurs when a parent account accepts a request to suspend the filter. As long as the parent accepted the request, this event is normal.',
    personName: 'Jimmy',
    deviceName: 'MacBook Air 13-inch, M2',
    time: '8:30 PM',
    date: 'May 14, 2026',
    severity: 'medium',
  },
  {
    type: 'mac-app',
    title: 'Filter suspension granted by admin',
    subtitle: 'For 30 min',
    explanation:
      'This event occurs when a filter suspension is granted from the computer by an admin-privileged user. If a parent did not authenticate, this represents the child suspending the filter themselves.',
    personName: 'Maggie',
    deviceName: 'Kitchen iMac',
    time: '10:41 AM',
    date: 'May 12, 2026',
    severity: 'high',
  },
  {
    type: 'mac-app',
    title: 'Blocked app launch attempted',
    subtitle: 'App: Music',
    explanation:
      'This event occurs when a child tries to launch an app designated blocked by the parent. There is no security risk as Gertrude will not allow the app to open, but repeated events do represent an attempt by the child to launch forbidden apps.',
    personName: 'Maggie',
    deviceName: 'Kitchen iMac',
    time: '10:38 AM',
    date: 'May 12, 2026',
    severity: 'medium',
  },
];

/// --- suspension requests ---

export type SuspensionRequest = {
  personName: string;
  duration: string; // '1 hour', '45 minutes', etc.
  reason?: string; // 'Need to turn in my assignment', 'YouTube video for school', etc.
};

export const mockSuspensionRequests: SuspensionRequest[] = [
  {
    personName: 'Sally',
    duration: '15 minutes',
    reason: "I need to check the group chat about tomorrow's carpool.",
  },
  {
    personName: 'Jimmy',
    duration: '2 hours',
  },
  {
    personName: 'Maggie',
    duration: '1 hour',
    reason: 'Can I play Minecraft with cousins after chores?',
  },
  {
    personName: 'Jimmy',
    duration: '30 minutes',
    reason: 'Need to submit my science worksheet and upload the photos.',
  },
  {
    personName: 'Theo',
    duration: '45 minutes',
    reason: 'Watching the volcano video for homework.',
  },
];

/// --- unlock requests ---

export type UnlockRequest = {
  domains: string[];
  personName: string;
  reason?: string;
};

export const mockUnlockRequests: UnlockRequest[] = [
  {
    personName: 'Maggie',
    domains: [
      'minecraft.net',
      'www.minecraft.net',
      'launcher.mojang.com',
      'resources.download.minecraft.net',
      'libraries.minecraft.net',
      'piston-meta.mojang.com',
      'sessionserver.mojang.com',
      'authserver.mojang.com',
    ],
    reason: 'Installing the update before playing with cousins.',
  },
  {
    personName: 'Jimmy',
    domains: ['scratch.mit.edu'],
  },
  {
    personName: 'Sally',
    domains: ['docs.google.com'],
    reason: 'Working on the history slideshow with my group.',
  },
  {
    personName: 'Jimmy',
    domains: ['khanacademy.org', 'cdn.kastatic.org'],
    reason: 'Need the practice problems and videos for math homework.',
  },
  {
    personName: 'Theo',
    domains: ['youtube.com', 'youtu.be'],
    reason: 'Watching the volcano experiment video for school.',
  },
];
