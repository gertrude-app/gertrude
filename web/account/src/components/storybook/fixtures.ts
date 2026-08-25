import type {
  AllowedAlbum,
  Device,
  InstalledMacApp,
  Keychain,
  Notification,
  NotificationMethod,
  PersonCardPerson,
  PersonIosSettingsConfiguration,
  Schedule,
  SecurityEvent,
  SuspensionRequest,
  UnlockRequest,
} from '#/components/types';
import type { Testimonial } from '#/components/unauthed/RotatingTestimonials';
import type { ActivityItem, DaySummary } from '#/lib/activity';

export const weekdaySchedule: Schedule = {
  type: `active`,
  days: {
    sunday: false,
    monday: true,
    tuesday: true,
    wednesday: true,
    thursday: true,
    friday: true,
    saturday: false,
  },
  startTime: { hour: 8, minute: 0 },
  endTime: { hour: 16, minute: 0 },
};

export const macDevice: Device = {
  id: `mac-1`,
  personId: `person-1`,
  type: `mac`,
  name: `Jude's MacBook`,
  macOSVersion: `15.6`,
  modelName: `MacBook Air`,
  modelIdentifier: `MacBookAir10,1`,
  online: true,
};

export const iphoneDevice: Device = {
  id: `iphone-1`,
  personId: `person-1`,
  type: `iphone`,
  iOSVersion: `18.5`,
  modelName: `iPhone 15 Pro`,
  modelIdentifier: `iPhone16,1`,
};

export const ipadDevice: Device = {
  id: `ipad-1`,
  personId: `person-2`,
  type: `ipad`,
  iOSVersion: `18.5`,
  modelName: `iPad Air`,
  modelIdentifier: `iPad13,16`,
};

export const devices: Device[] = [macDevice, iphoneDevice, ipadDevice];

export const people: PersonCardPerson[] = [
  {
    id: `person-1`,
    name: `Jude`,
    relationship: `child`,
    devices: devices.slice(0, 2),
    screenshot: {
      url: `/example-screenshots/kid-school.png`,
      recency: `4 minutes ago`,
    },
  },
  {
    id: `person-2`,
    name: `Mabel`,
    relationship: `child`,
    devices: [ipadDevice],
    screenshot: null,
  },
  {
    id: `person-3`,
    name: `Caleb`,
    relationship: `peer`,
    devices: [],
    screenshot: null,
  },
];

export const keychains: Keychain[] = [
  {
    id: `keychain-school`,
    name: `School stuff`,
    description: `Research, homework, and class resources.`,
    numKeys: 43,
    isPublic: false,
  },
  {
    id: `keychain-games`,
    name: `Games`,
    description: `Approved game sites and launchers.`,
    numKeys: 12,
    isPublic: false,
  },
  {
    id: `keychain-music`,
    name: `Music`,
    description: `Streaming and lyrics sites with safer defaults.`,
    numKeys: 18,
    isPublic: true,
  },
  {
    id: `keychain-google-docs`,
    name: `Google Docs`,
    description: `Documents, presentations, and shared classroom files.`,
    warning: `Image search results may include inappropriate content.`,
    numKeys: 27,
    isPublic: true,
  },
];

export const installedMacApps: InstalledMacApp[] = [
  {
    id: `app-safari`,
    name: `Safari`,
    bundleId: `com.apple.Safari`,
    appIconUrl: `/example-app-icons/safari.webp`,
  },
  {
    id: `app-chrome`,
    name: `Google Chrome`,
    bundleId: `com.google.Chrome`,
    appIconUrl: `/example-app-icons/chrome.webp`,
  },
  {
    id: `app-minecraft`,
    name: `Minecraft`,
    bundleId: `com.mojang.minecraftlauncher`,
    appIconUrl: `/example-app-icons/minecraft.webp`,
  },
  {
    id: `app-discord`,
    name: `Discord`,
    bundleId: `com.hnc.Discord`,
    appIconUrl: `/example-app-icons/discord.webp`,
  },
  {
    id: `app-scratch`,
    name: `Scratch`,
    bundleId: `edu.mit.scratch`,
    appIconUrl: `/example-app-icons/scratch.webp`,
  },
];

export const albums: AllowedAlbum[] = [
  {
    title: `Abbey Road`,
    artist: `The Beatles`,
    artworkUrl: `https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/df/db/61/dfdb615d-47f8-06e9-9533-b96daccc029f/18UMGIM31076.rgb.jpg/300x300bb.jpg`,
    showAlbumArt: true,
  },
  {
    title: `The Muppet Movie`,
    artist: `Kermit the Frog`,
    artworkUrl: `https://is1-ssl.mzstatic.com/image/thumb/Music118/v4/0f/d8/15/0fd815cb-45f4-b334-e26d-0ea9875795e3/00050087348533.rgb.jpg/300x300bb.jpg`,
    showAlbumArt: true,
  },
  {
    title: `The Planets`,
    artist: `Gustav Holst`,
    artworkUrl: `https://picsum.photos/seed/the-planets/300/300`,
    showAlbumArt: false,
  },
  {
    title: `Minecraft Volume Alpha`,
    artist: `C418`,
    artworkUrl: `https://picsum.photos/seed/minecraft-volume-alpha/300/300`,
    showAlbumArt: true,
  },
];

export const iosSettings: PersonIosSettingsConfiguration = {
  blockedGroups: {
    appleMusic: true,
    whatsApp: true,
    musicRecognition: true,
    gifs: true,
    appleMapsImages: false,
    aiFeatures: true,
    appStoreImages: false,
    spotlight: true,
    ads: true,
    appleDotCom: false,
    spotifyImages: true,
  },
  preventProtectionRemoval: true,
  allowDeletingApps: false,
  allowFactoryReset: false,
  allowInstallingApps: true,
  allowedAlbums: albums.slice(0, 3),
};

export const unlockRequests: UnlockRequest[] = [
  {
    id: `unlock-1`,
    personName: `Jude`,
    domains: [
      `wikipedia.org`,
      `khanacademy.org`,
      `nasa.gov`,
      `scratch.mit.edu`,
      `mit.edu`,
    ],
    reason: `I need these for my science report.`,
    reviewHref: `/requests/unlock/unlock-1`,
  },
  {
    id: `unlock-2`,
    personName: `Mabel`,
    domains: [`lego.com`, `pbs.org`],
  },
];

export const suspensionRequests: SuspensionRequest[] = [
  {
    id: `suspension-1`,
    personId: `person-1`,
    personName: `Jude`,
    deviceName: `Jude's MacBook`,
    requestedDurationInSeconds: 30 * 60,
    duration: `30 minutes`,
    reason: `I need to download a school project from Google Drive.`,
    extraMonitoringOptions: {
      k: `keylogging`,
      '@90': `1.5x screenshots`,
      '@60': `2x screenshots`,
      '@30': `3x screenshots`,
      '@90+k': `1.5x screenshots + keylogging`,
      '@60+k': `2x screenshots + keylogging`,
      '@30+k': `3x screenshots + keylogging`,
    },
  },
  {
    id: `suspension-2`,
    personId: `person-2`,
    personName: `Mabel`,
    requestedDurationInSeconds: 5 * 60,
    duration: `5 minutes`,
    extraMonitoringOptions: {},
  },
];

export const securityEvents: SecurityEvent[] = [
  {
    id: `security-1`,
    type: `mac-app`,
    title: `Filter suspension granted by admin`,
    detail: `for 30 minutes`,
    explanation: `This event occurs when a filter suspension is granted from the computer by an admin-privileged user. If a parent did not authenticate, this represents the protected person suspending the filter themselves.`,
    createdAt: new Date(2026, 6, 3, 9, 42),
    severity: `high`,
    personId: `person-1`,
    personName: `Jude`,
    deviceId: `mac-1`,
    deviceName: `Jude's MacBook`,
  },
  {
    id: `security-2`,
    type: `account`,
    title: `Failed login`,
    detail: `incorrect password`,
    explanation: `This event occurs whenever a parent fails to log in to Gertrude Account, usually because of an incorrect password. Investigate it if you do not recognize the attempt.`,
    createdAt: new Date(2026, 6, 3, 7, 15),
    severity: `medium`,
    ipAddress: `203.0.113.42`,
  },
  {
    id: `security-3`,
    type: `mac-app`,
    title: `App launched`,
    explanation: `This event occurs when the Gertrude app is launched. Only investigate it if it seems to be occurring more than expected.`,
    createdAt: new Date(2026, 6, 3, 6, 30),
    severity: `low`,
    personId: `person-2`,
    personName: `Mabel`,
    deviceId: `mac-2`,
    deviceName: `Mac mini`,
  },
  {
    id: `security-4`,
    type: `account`,
    title: `Blocked apps changed`,
    detail: `person: Jude`,
    explanation: `This event occurs when an account owner changes which apps are blocked for a protected person. Investigate it if the change was not made by you.`,
    createdAt: new Date(2026, 6, 2, 20, 18),
    severity: `high`,
    ipAddress: `198.51.100.17`,
  },
  {
    id: `security-5`,
    type: `mac-app`,
    title: `System clock or time zone changed`,
    detail: `America/New_York → America/Chicago`,
    explanation: `A clock or time zone change can be an attempt to circumvent time-based restrictions in Gertrude. Check whether there was a legitimate reason for this change.`,
    createdAt: new Date(2026, 6, 2, 14, 5),
    severity: `medium`,
    personId: `person-1`,
    personName: `Jude`,
    deviceId: `mac-1`,
    deviceName: `Jude's MacBook`,
  },
  {
    id: `security-6`,
    type: `account`,
    title: `Successful login`,
    detail: `using magic link`,
    explanation: `This event occurs whenever an account owner successfully logs in. Investigate it if you do not recognize the login as your own.`,
    createdAt: new Date(2026, 5, 29, 11, 22),
    severity: `low`,
    ipAddress: `203.0.113.42`,
  },
];

export const emailNotificationMethod: NotificationMethod = {
  id: `method-email`,
  type: `email`,
  emailAddress: `parent@example.com`,
};

export const textNotificationMethod: NotificationMethod = {
  id: `method-text`,
  type: `text`,
  phoneNumber: `+15555550142`,
};

export const slackNotificationMethod: NotificationMethod = {
  id: `method-slack`,
  type: `slack`,
  channelName: `gertrude-alerts`,
  channelId: `C08GERTRUDE`,
  botToken: `xoxb-example`,
};

export const ntfyNotificationMethod: NotificationMethod = {
  id: `method-ntfy`,
  type: `ntfy`,
  topicId: `gertrude-family-alerts-8k4tq9`,
};

export const pushNotificationMethod: NotificationMethod = {
  id: `method-push`,
  type: `push`,
};

export const notificationMethods: NotificationMethod[] = [
  emailNotificationMethod,
  textNotificationMethod,
  slackNotificationMethod,
  ntfyNotificationMethod,
  pushNotificationMethod,
];

export const notifications: Notification[] = [
  {
    id: `notification-1`,
    methodId: `method-email`,
    trigger: `unlockRequestSubmitted`,
    enabled: true,
    method: emailNotificationMethod,
  },
  {
    id: `notification-2`,
    methodId: `method-ntfy`,
    trigger: `securityEventsRecommended`,
    enabled: true,
    method: ntfyNotificationMethod,
  },
];

export const daySummaries: DaySummary[] = [
  {
    date: new Date(2026, 6, 3),
    stats: {
      totalCount: 42,
      deletedCount: 12,
      flaggedCount: 3,
      reviewedCount: 15,
      reviewedPercent: 35.7,
    },
  },
  {
    date: new Date(2026, 6, 2),
    stats: {
      totalCount: 18,
      deletedCount: 18,
      flaggedCount: 0,
      reviewedCount: 18,
      reviewedPercent: 100,
    },
  },
];

export const activityItems: ActivityItem[] = [
  {
    id: `activity-1`,
    personId: `person-1`,
    personName: `Jude`,
    duringSuspension: false,
    date: new Date(2026, 6, 3, 9, 30),
    flagged: false,
    deleted: false,
    type: `screenshot`,
    url: `/example-screenshots/kid-school.png`,
    width: 1200,
    height: 760,
  },
  {
    id: `activity-2`,
    personId: `person-1`,
    personName: `Jude`,
    duringSuspension: true,
    date: new Date(2026, 6, 3, 9, 42),
    flagged: true,
    deleted: false,
    type: `keylog`,
    text: `searched: minecraft server mods\nopened discord invite`,
    applicationName: `Google Chrome`,
  },
  {
    id: `activity-2b`,
    personId: `person-1`,
    personName: `Jude`,
    duringSuspension: true,
    date: new Date(2026, 6, 3, 9, 44),
    flagged: false,
    deleted: false,
    type: `screenshot`,
    url: `/example-screenshots/programmer.png`,
    width: 1200,
    height: 760,
  },
  {
    id: `activity-3`,
    personId: `person-2`,
    personName: `Mabel`,
    duringSuspension: false,
    date: new Date(2026, 6, 3, 10, 5),
    flagged: false,
    deleted: false,
    type: `screenshot`,
    url: `/example-screenshots/programmer.png`,
    width: 1200,
    height: 760,
  },
];

export const testimonials: Testimonial[] = [
  {
    quote: `Thanks for the hard work you put into making this app. An absolute masterpiece and likely the greatest blessing an app has had on our lives.`,
    name: `Austin944`,
  },
  {
    quote: `Saved my young son from looking at porn through the maps app. You are a lifesaver.`,
    name: `GratefulMom55`,
  },
  {
    quote: `Finally a way to block GIFS!!! Thank you, thank you, thank you!!!`,
    name: `HAAS1988`,
  },
  {
    quote: `Using this for my kids’ iPhones with Apple Configurator and screen time controls has made the phones far safer.`,
    name: `sraragan`,
  },
  {
    quote: `This app is meeting a great need since Apple has not allowed parents to properly protect their children.`,
    name: `Apple280`,
  },
  {
    quote: `Apple Screen Time has some helpful features, but Gertrude Blocker plugs the holes Apple missed.`,
    name: `Henderjay`,
  },
];
