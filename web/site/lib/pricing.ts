export const pricingPlans = {
  free: {
    name: `Free`,
    priceDollars: 0,
    billingPeriod: null,
    summary: `Gertrude Blocker highlights:`,
    features: [
      `Block GIFs, web images, explicit artwork, ads & more`,
      `Close loopholes in Messages, Spotlight, Maps and other apps`,
      `Choose what to block on each device, from anywhere`,
    ],
  },
  light: {
    name: `Light`,
    priceDollars: 10,
    billingPeriod: `year`,
    summary: `Everything in Free, plus:`,
    features: [
      `Protect adult iPhones & iPads (18+)`,
      `Set up supervised mode without erasing your device`,
      `Control app installs and other device restrictions`,
      `Listen to approved shows with Gertrude Podcasts`,
      `Keep new podcast searches behind a PIN`,
    ],
  },
  medium: {
    name: `Medium`,
    priceDollars: 5,
    billingPeriod: `month`,
    summary: `Everything in Light, plus Gertrude Music:`,
    features: [
      `Choose their library from the Apple Music catalog`,
      `Let them build playlists from approved music`,
      `Enjoy shuffle, repeat & Infinite Play`,
      `Manage their music from any browser`,
    ],
  },
  full: {
    name: `Full`,
    priceDollars: 10,
    billingPeriod: `month`,
    summary: `Everything in Medium, plus Gertrude for Mac:`,
    features: [
      `Block everything except what you approve, on every Mac`,
      `See what’s happening with screenshot monitoring`,
      `Review typed activity with keylogging`,
      `Block unwanted apps & schedule downtime`,
      `Approve unlock and temporary access requests from anywhere`,
    ],
  },
} as const;

export const lightMonthlyEquivalentCents = Math.floor(
  (pricingPlans.light.priceDollars * 100) / 12,
);

export const freeTrialDays = {
  mac: 21,
  music: 21,
  podcasts: 30,
} as const;
