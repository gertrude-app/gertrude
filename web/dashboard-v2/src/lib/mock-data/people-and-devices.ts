export type Device =
  | {
      type: `mac`;
      name?: string;
      macOSVersion: string;
      modelName: string;
      online: boolean;
    }
  | {
      type: `iphone` | `ipad`;
      iOSVersion: string;
      modelName: string;
    };

export type Person = {
  id: string;
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
  type: `ipad`,
  iOSVersion: `18.4`,
  modelName: `iPad (10th generation)`,
};

const schoolMacBook: Device = {
  type: `mac`,
  macOSVersion: `15.4`,
  modelName: `MacBook Air 13-inch, M2`,
  online: true,
};

const kitchenIMac: Device = {
  type: `mac`,
  name: `Kitchen iMac`,
  macOSVersion: `14.7`,
  modelName: `iMac 24-inch, M1`,
  online: false,
};

export const mockChildren: Person[] = [
  {
    id: `jimmy`,
    name: `Jimmy`,
    devices: [familyIpad, schoolMacBook],
    screenshot: {
      url: `/example-screenshots/kid-school.png`,
      recency: `3 minutes ago`,
    },
    musicListening: {
      trackName: `Here Comes the Sun`,
      artistName: `The Beatles`,
      albumArtUrl: `https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/df/db/61/dfdb615d-47f8-06e9-9533-b96daccc029f/18UMGIM31076.rgb.jpg/300x300bb.jpg`,
      recencyInMinutes: 0,
    },
    podcastListening: {
      title: `How Volcanoes Work`,
      podcastName: `Brains On!`,
      artworkUrl: `https://is1-ssl.mzstatic.com/image/thumb/Podcasts211/v4/99/e5/39/99e53993-e2ea-70a3-64d6-f2f86ab84e53/mza_8458923780593912977.jpg/300x300bb.jpg`,
      recencyInMinutes: 3,
    },
  },
  {
    id: `sally`,
    name: `Sally`,
    devices: [
      {
        type: `iphone`,
        iOSVersion: `18.3`,
        modelName: `iPhone 14`,
      },
      familyIpad,
      kitchenIMac,
    ],
    screenshot: null,
    musicListening: {
      trackName: `Rainbow Connection`,
      artistName: `Kermit the Frog`,
      albumArtUrl: `https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/0f/d8/15/0fd815cb-45f4-b334-e26d-0ea9875795e3/00050087348533.rgb.jpg/300x300bb.jpg`,
      recencyInMinutes: 57,
    },
    podcastListening: null,
  },
  {
    id: `franny`,
    name: `Franny`,
    devices: [],
    screenshot: null,
    musicListening: null,
    podcastListening: null,
  },
  {
    id: `theo`,
    name: `Theo`,
    devices: [
      {
        type: `ipad`,
        iOSVersion: `17.7`,
        modelName: `iPad mini (6th generation)`,
      },
    ],
    screenshot: null,
    musicListening: null,
    podcastListening: {
      title: `The Case of the Missing Moon Rocks`,
      podcastName: `Wow in the World`,
      artworkUrl: `https://is1-ssl.mzstatic.com/image/thumb/Podcasts211/v4/4c/b0/4a/4cb04a06-4e0a-d534-2a28-3f2fb37fa14e/mza_14610475686329584932.jpeg/300x300bb.jpg`,
      recencyInMinutes: 0,
    },
  },
  {
    id: `maggie`,
    name: `Maggie`,
    devices: [
      {
        type: `iphone`,
        iOSVersion: `18.4`,
        modelName: `iPhone SE (3rd generation)`,
      },
      schoolMacBook,
      kitchenIMac,
    ],
    screenshot: {
      url: `/example-screenshots/minecraft.png`,
      recency: `18 minutes ago`,
    },
    musicListening: null,
    podcastListening: null,
  },
];

export function getMockChildById(personId: string): Person | undefined {
  return mockChildren.find((child) => child.id === personId);
}
