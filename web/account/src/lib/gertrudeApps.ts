import type { GetAccountIOSClaimData, SetupApp } from '@shared/pairql/src/account';

type AppDetails = {
  name: string;
  shortName: string;
  icon: string;
  iconOutlined: boolean;
  appStoreUrl?: string;
};

export const gertrudeApps = {
  mac: {
    name: `Gertrude for Mac`,
    shortName: `Mac`,
    icon: `/gertrude-app-icons/blocker.webp`,
    iconOutlined: true,
  },
  blocker: {
    name: `Gertrude Blocker`,
    shortName: `Blocker`,
    icon: `/gertrude-app-icons/blocker.webp`,
    iconOutlined: true,
    appStoreUrl: `https://apps.apple.com/app/id6736368820`,
  },
  music: {
    name: `Gertrude Music`,
    shortName: `Music`,
    icon: `/gertrude-app-icons/music.webp`,
    iconOutlined: false,
    appStoreUrl: `https://apps.apple.com/app/id6782194077`,
  },
  podcasts: {
    name: `Gertrude Podcasts`,
    shortName: `Podcasts`,
    icon: `/gertrude-app-icons/podcasts.webp`,
    iconOutlined: false,
    appStoreUrl: `https://apps.apple.com/app/id6753187429`,
  },
} as const satisfies Record<SetupApp, AppDetails>;

export type IOSConnectFlow = GetAccountIOSClaimData.Input[`flow`];

export const appForConnectFlow = (
  flow: IOSConnectFlow,
): `blocker` | `podcasts` | `music` =>
  flow === `podcasts` || flow === `music` ? flow : `blocker`;
