import type { SetupApp } from '@shared/pairql/src/account';

export type { SetupApp };

export type IOSSetupApp = Exclude<SetupApp, `mac`>;

export const appStoreUrls: Record<IOSSetupApp, string> = {
  blocker: `https://apps.apple.com/app/id6736368820`,
  music: `https://apps.apple.com/app/id6782194077`,
  podcasts: `https://apps.apple.com/app/id6753187429`,
};

export const setupApps: {
  id: SetupApp;
  name: string;
  platforms: (`mac` | `iphone` | `ipad`)[];
  description: string;
  instructions: string;
  icon: string;
}[] = [
  {
    id: `mac`,
    name: `Gertrude for Mac`,
    platforms: [`mac`],
    description: `Deny-by-default filtering and activity monitoring.`,
    instructions: `Install Gertrude on their Mac and connect it to your account.`,
    icon: `/gertrude-app-icons/blocker.webp`,
  },
  {
    id: `blocker`,
    name: `Gertrude Blocker`,
    platforms: [`iphone`, `ipad`],
    description: `Close the gaps in Apple’s Screen Time protections.`,
    instructions: `Install it on their iPhone or iPad and connect it to your account. Then choose what to block.`,
    icon: `/gertrude-app-icons/blocker.webp`,
  },
  {
    id: `music`,
    name: `Gertrude Music`,
    platforms: [`iphone`, `ipad`],
    description: `Parent-approved music, without open-ended browsing.`,
    instructions: `Install it on their iPhone or iPad and connect it to your account. Then choose the music they can play.`,
    icon: `/gertrude-app-icons/music.webp`,
  },
  {
    id: `podcasts`,
    name: `Gertrude Podcasts`,
    platforms: [`iphone`, `ipad`],
    description: `Approved podcasts, with a PIN to add new shows.`,
    instructions: `Install it on their iPhone or iPad, connect it to your account, and set a PIN for adding new shows.`,
    icon: `/gertrude-app-icons/podcasts.webp`,
  },
];

export type SetupStepId = `person` | `choose-apps` | SetupApp;

export type SetupStep = {
  id: SetupStepId;
  title: string;
  description: string;
  icon?: string;
};

export const personSetupStep: SetupStep = {
  id: `person`,
  title: `Who would you like to protect?`,
  description: `Create a profile for your child, yourself, or someone you’re helping protect.`,
};

export const getAppSetupSteps = (selectedApps: SetupApp[]): SetupStep[] => {
  const apps = setupApps.filter((app) => selectedApps.includes(app.id));
  if (apps.length === 0) {
    return [
      {
        id: `choose-apps`,
        title: `Choose an app to set up`,
        description: `Pick the Gertrude app you’d like to use first.`,
      },
    ];
  }
  return apps.map((app) => ({
    id: app.id,
    title: `Set up ${app.name}`,
    description: app.instructions,
    icon: app.icon,
  }));
};
