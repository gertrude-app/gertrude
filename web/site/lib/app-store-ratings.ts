export interface AppStoreRating {
  name: string;
  rating: string;
  count: number | null;
  url: string;
}

export const appStoreRatings = {
  blocker: {
    name: `Gertrude Blocker`,
    rating: `4.9`,
    count: 153,
    url: `https://apps.apple.com/us/app/gertrude-blocker/id6736368820`,
  },
  podcasts: {
    name: `Gertrude Podcasts`,
    rating: `4.8`,
    count: 30,
    url: `https://apps.apple.com/us/app/gertrude-podcasts/id6753187429`,
  },
  music: {
    name: `Gertrude Music`,
    rating: `5.0`,
    count: null,
    url: `https://apps.apple.com/us/app/gertrude-music/id6782194077`,
  },
} as const satisfies Record<string, AppStoreRating>;
