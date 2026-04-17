import { Onboarding } from '@macos/appviews';
import {
  CreateUserForm,
  LogoutConfirmModal,
  PostCreateConfirm,
} from '@macos/appviews/src/Onboarding/Steps/MacosUserAccountType';
import React from 'react';
import type { Meta, StoryObj } from '@storybook/react';
import { appWindow, props } from '../story-helpers';

function fakeIcon(letter: string, color: string): string {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="128" height="128" rx="28" fill="${color}"/><text x="64" y="64" text-anchor="middle" dominant-baseline="central" font-size="64" font-family="system-ui" fill="white">${letter}</text></svg>`;
  return `data:image/svg+xml;base64,${btoa(svg)}`;
}

const BASE_APPS = [
  {
    name: `Slack`,
    bundleId: `com.tinyspeck.slackmacgap`,
    iconPath: fakeIcon(`S`, `#611f69`),
    category: `public.app-category.business`,
  },
  {
    name: `Spotify`,
    bundleId: `com.spotify.client`,
    iconPath: fakeIcon(`S`, `#1db954`),
    category: `public.app-category.music`,
  },
  {
    name: `Zoom`,
    bundleId: `us.zoom.xos`,
    iconPath: fakeIcon(`Z`, `#2d8cff`),
    category: `public.app-category.video`,
  },
  {
    name: `Discord`,
    bundleId: `com.hnc.Discord`,
    iconPath: fakeIcon(`D`, `#5865f2`),
    category: `public.app-category.social-networking`,
  },
  {
    name: `Visual Studio Code`,
    bundleId: `com.microsoft.VSCode`,
    iconPath: fakeIcon(`V`, `#007acc`),
    category: `public.app-category.developer-tools`,
  },
  {
    name: `Notion`,
    bundleId: `notion.id`,
    iconPath: fakeIcon(`N`, `#000000`),
    category: `public.app-category.productivity`,
  },
  {
    name: `Figma`,
    bundleId: `com.figma.Desktop`,
    iconPath: fakeIcon(`F`, `#f24e1e`),
    category: `public.app-category.graphics-design`,
  },
  {
    name: `Steam`,
    bundleId: `com.valvesoftware.steam`,
    iconPath: fakeIcon(`S`, `#1b2838`),
    category: `public.app-category.games`,
  },
];

const STUB_APPS = [
  ...BASE_APPS,
  ...BASE_APPS.map((a) => ({ ...a, bundleId: `${a.bundleId}.2`, name: `${a.name} 2` })),
  ...BASE_APPS.map((a) => ({ ...a, bundleId: `${a.bundleId}.3`, name: `${a.name} 3` })),
];

const STUB_PUBLIC_KEYCHAINS = [
  { id: `e05c458e-f52b-492f-af9c-5aff7a77f743`, name: `Aceable Driver's Ed` },
  {
    id: `65901ee7-de72-4ce3-a582-615257befec4`,
    name: `Acellus Academy`,
    description: `https://www.acellusacademy.com`,
  },
  {
    id: `7941a8a7-3f90-4979-96f3-f36390a6fae4`,
    name: `Apple App Store`,
    description: `Gives unrestricted access to the Apple App Store.`,
    brandColor: `#0071E3`,
  },
  { id: `dd7f5b5a-be16-4b7d-a422-1cacf417e5c3`, name: `Art of Problem Solving (AOPS)` },
  {
    id: `42fac927-cb21-41e1-b3b9-acd35a34c51d`,
    name: `Audible`,
    description: `Listening to audio books on the audible.com website`,
    brandColor: `#F8991C`,
  },
  { id: `dacd30fd-f27b-4692-bed0-585a3bf4631c`, name: `Beast Academy` },
  {
    id: `ac9c9476-9f6b-4fb3-a8b0-8a97413dbf82`,
    name: `Blooket`,
    description: `www.blooket.com`,
  },
  {
    id: `7d176f5d-7d3a-4a91-b51f-cc4fbfe75e09`,
    name: `CBS Sports`,
    description: `www.cbssports.com`,
    brandColor: `#00326A`,
  },
  {
    id: `14b73379-c27d-407e-bac6-b153574afba2`,
    name: `CTCMath`,
    description: `https://www.ctcmath.com/ CTC Math`,
  },
  {
    id: `fd8564e6-4821-4ee8-94b4-6a240cc6cacc`,
    name: `Classical Academic Press`,
    description: `https://classicalacademicpress.com`,
  },
  { id: `fa465601-82a6-4d54-8bc5-0195b8687e83`, name: `Classical Conversations` },
  {
    id: `fa40e302-655b-4c8a-8c1d-17f167e446f7`,
    name: `Duolingo`,
    brandColor: `#58CC02`,
  },
  {
    id: `1feb6bab-8e58-42ee-b950-b4dedcb2fc65`,
    name: `ESPN`,
    description: `www.espn.com`,
    brandColor: `#D91A1F`,
  },
  {
    id: `36cc2959-2004-49d1-9eab-7afa611ba41f`,
    name: `ESV Bible`,
    description: `Keys for the ESV Bible website (esv.org)`,
  },
  {
    id: `5c0de91b-ea12-4e03-9d0c-73d4f890e2e6`,
    name: `Ebird`,
    description: `Cornell's Ebird website`,
  },
  {
    id: `b495baf6-a400-4f9d-bf85-cd50669d699a`,
    name: `Enlightium Academy`,
    description: `https://www.enlightiumacademy.com/`,
  },
  {
    id: `6bb65686-4354-46e3-a50c-c9d111190b2f`,
    name: `Gimkit`,
    description: `www.gimkit.com`,
  },
  {
    id: `09a9092e-aa4f-42be-8237-9d05e455922f`,
    name: `Gmail`,
    brandColor: `#EA4335`,
  },
  {
    id: `45bf86e8-fe9c-454f-97dc-91d24ab2a067`,
    name: `Google Classroom`,
    description: `classroom.google.com`,
    brandColor: `#1A73E8`,
  },
  {
    id: `3f092324-045e-4c71-82aa-cfaed6ff7ec7`,
    name: `Google Drive/Docs`,
    description: `Google Drive and Google Docs`,
    brandColor: `#1A73E8`,
  },
  {
    id: `81e4b053-81db-42e6-b6e2-aeca5bd38e41`,
    name: `GrammarFlip`,
    description: `www.grammarflip.com`,
  },
  {
    id: `e05d14a1-2d73-4816-9061-c4e9b36fcc4a`,
    name: `Hubspot`,
    description: `Unlocks the hubspot.com website and service.`,
  },
  {
    id: `ae36d0d1-cba5-43ff-94f7-3dc71b520779`,
    name: `Institute for Excellence in Writing (IEW)`,
    description: `https://iew.com`,
  },
  {
    id: `b537e786-2ba9-4f49-bc98-ea9393019b22`,
    name: `Instructure Canvas`,
    brandColor: `#D64027`,
  },
  {
    id: `05cfed07-a65c-41bb-8329-0639a13adbca`,
    name: `Joon`,
    description: `Joon Behavior Improvement and Joon Pet Game apps`,
  },
  {
    id: `d96e5bea-aba2-4787-9938-58c87c2eb07f`,
    name: `Khan Academy`,
    description: `www.khanacademy.org`,
    brandColor: `#14BF96`,
  },
  {
    id: `51625ded-c114-43db-ba43-aace7fa4a680`,
    name: `LEGO Spike`,
    description: `spike.legoeducation.com`,
  },
  { id: `47847be8-63be-4269-9427-a8cec09637ff`, name: `Learncraft Spanish` },
  { id: `d748fe33-b60a-497a-a99a-7e3584fa9f19`, name: `Magoosh` },
  {
    id: `1519cdc3-1686-401c-81f4-97a48d1c7443`,
    name: `Minecraft: Education Edition`,
    description: `education.minecraft.net`,
  },
  {
    id: `1f8162cd-32f9-4703-9c14-ebb8c2c38f73`,
    name: `National Geographic Kids`,
    description: `kids.nationalgeographic.com`,
  },
  {
    id: `10c3d2ae-ea1e-4347-b2f0-3b1998a153b0`,
    name: `Noteflight`,
    description: `www.noteflight.com`,
  },
  {
    id: `6e334645-b93a-4192-bae8-44fc4c360671`,
    name: `Oxford Discover Futures`,
    description: `https://oxforddiscoverfutures.oxfordonlinepractice.com`,
  },
  {
    id: `8e54bf38-1d8c-471c-b0cf-3d531070ff04`,
    name: `PBS Kids`,
    description: `www.pbskids.org`,
  },
  {
    id: `c1212f58-5d92-4a25-9433-7ff18edaf1fb`,
    name: `Preply`,
    description: `preply.com - language learning and lessons.`,
  },
  {
    id: `070ad71d-df5b-4646-8ae7-123c1d5fb317`,
    name: `Robotel / SmartClass`,
    description: `https://www.robotel.com - SmartClass by Robotel`,
  },
  { id: `f4364531-7977-4d17-86ed-482eb4ff8337`, name: `Rocket Languages` },
  { id: `a27c4c94-6def-4276-8139-e0ef4ff206b8`, name: `Rosetta Stone` },
  {
    id: `fae778df-4e94-4e99-b670-f703c3205fe4`,
    name: `Skype App`,
    description: `Grants the Skype App unrestricted access to the internet.`,
    brandColor: `#00AFF0`,
  },
  { id: `c15d84fd-9afc-4482-b215-b1543f342e27`, name: `Spanish Dictionary` },
  { id: `1cdfc1fc-6c6b-4439-b8cd-e3c79810dcd7`, name: `Teaching Textbooks App` },
  {
    id: `3b982428-3b66-418f-a286-da59d98227f0`,
    name: `The Good and the Beautiful`,
    description: `goodandbeautiful.com`,
  },
  {
    id: `aba6256b-32fd-43b0-a325-50a6f6611ee9`,
    name: `Time4Learning`,
    description: `www.time4learning.com`,
  },
  { id: `4b9b7fca-091b-443f-8abb-ca7c8f48dc83`, name: `Typesy` },
  { id: `63330b68-32c6-42a9-849c-714cafb36f26`, name: `Unrestricted Apple Mail` },
  {
    id: `099c9aa6-e431-4bef-8095-67add439ca34`,
    name: `Unrestricted Zoom App`,
    description: `Allows the Zoom app totally unrestricted access to the internet, as well as web access to the zoom.us website for joining meetings.`,
    brandColor: `#2D8CFF`,
  },
  {
    id: `cf6d3caa-a44f-44c9-b0fd-eeb43b91ec7e`,
    name: `World Watch News`,
    description: `https://worldwatch.news`,
  },
  { id: `2d8d1bf5-21c1-44e7-9802-b73e7a2d7992`, name: `Xtra Math` },
  {
    id: `d62923cd-5088-4a10-9425-6d67a23e97ee`,
    name: `YouTube Kids`,
    description: `www.youtubekids.com`,
    brandColor: `#FF0000`,
  },
  {
    id: `14cd685b-dcf1-46e6-bc5b-2fa1ec8e10f0`,
    name: `iCloud Apps`,
    description: `Messages, Photos, Facetime`,
  },
];

const ADULT_CONTENT = `5eea4c3e-3910-4ca3-bcac-09af52a2f567`;
const MESSAGES_GIF = `e8f90637-22d5-4525-abe1-cde1d3cbbd33`;
const SOCIAL_MEDIA = `a032f240-00a7-467d-a27f-5987c714818a`;
const SPOTLIGHT_SEARCH = `ce7c5aef-9754-44aa-af3b-e1f8900f0b25`;

const ALWAYS_BLOCKED_GROUPS = [
  {
    id: SOCIAL_MEDIA,
    name: `Social media`,
    description: `Block the most prominent social media sites.`,
    longDescription: `not real`,
  },
  {
    id: MESSAGES_GIF,
    name: `Messages GIF Search`,
    description: `Block the #images GIF picker in Messages and common GIF providers.`,
    longDescription: `not real`,
  },
  {
    id: ADULT_CONTENT,
    name: `Adult content`,
    description: `Block the most-trafficked adult websites, plus adult-oriented TLDs.`,
    longDescription: `not real`,
  },
  {
    id: SPOTLIGHT_SEARCH,
    name: `Spotlight search`,
    description: `Block web results in macOS Spotlight search.`,
    longDescription: `not real`,
  },
];

const meta = {
  title: 'MacOS App/Onboarding', // eslint-disable-line
  component: Onboarding,
  ...appWindow(900, 700),
} satisfies Meta<typeof Onboarding>;

type Story = StoryObj<typeof meta>;

export const Welcome: Story = props({
  windowOpen: true,
  osVersion: { name: `tahoe`, major: 26 },
  step: `welcome`,
  connectChildRequest: { case: `idle` },
  screenRecordingPermissionGranted: false,
  keyloggingPermissionGranted: false,
  currentUser: { id: 502, name: `Suzy`, isAdmin: false },
  logoutConfirmVisible: false,
  createUserRequest: { case: `idle` },
  users: [
    { id: 503, name: `Little Jimmy`, isAdmin: false },
    { id: 501, name: `Bob McParent`, isAdmin: true },
    { id: 502, name: `Suzy`, isAdmin: false },
  ],
  exemptableUserIds: [501, 503],
  exemptUserIds: [501],
  connectionCode: ``,
  didResume: false,
  receivedAppState: true,
  isUpgrade: false,
  discoveredApps: [],
  publicKeychains: [],
  alwaysBlocked: { groups: [], preselected: [] },
  customKeychainDomains: [],
  createCustomKeychainRequest: { case: `idle` },
  blockedBundleIds: [],
  createAppKeysRequest: { case: `idle` },
  emit: () => {},
  dispatch: () => {},
});

export const WrongInstallDir: Story = props({
  ...Welcome.args,
  step: `wrongInstallDir`,
});

export const MacUserAdminWarn: Story = props({
  ...Welcome.args,
  step: `macosUserAccountType`,
  currentUser: { id: 501, name: `Bob McParent`, isAdmin: true },
  users: [{ id: 501, name: `Bob McParent`, isAdmin: true }],
});

export const MacUserAdminChoose: Story = props({
  ...MacUserAdminWarn.args,
  userRemediationStep: `choose`,
  users: [
    { id: 501, name: `Bob McParent`, isAdmin: true },
    { id: 502, name: `Sally McMom`, isAdmin: true },
    { id: 503, name: `Little Jimmy`, isAdmin: false },
  ],
});

export const MacUserAdminChooseNoDemote: Story = props({
  ...MacUserAdminWarn.args,
  userRemediationStep: `choose`,
  users: [
    { id: 501, name: `Bob McParent`, isAdmin: true },
    { id: 503, name: `Little Jimmy`, isAdmin: false },
  ],
});

export const MacUserAdminChooseNoSwitch: Story = props({
  ...MacUserAdminWarn.args,
  userRemediationStep: `choose`,
  users: [
    { id: 501, name: `Bob McParent`, isAdmin: true },
    { id: 502, name: `Sally McMom`, isAdmin: true },
  ],
});

export const MacUserSwitchFallbackTutorial: Story = props({
  ...MacUserAdminWarn.args,
  userRemediationStep: `switch`,
});

export const MacUserDemoteInstructions: Story = props({
  ...MacUserAdminWarn.args,
  userRemediationStep: `demote`,
});

export const MacUserCreateFallbackTutorial: Story = props({
  ...MacUserAdminWarn.args,
  userRemediationStep: `create`,
});

export const MacUserLogoutConfirm: Story = {
  ...props(Welcome.args!),
  render: () => (
    <div className="fixed inset-0 bg-slate-50">
      <LogoutConfirmModal currentUserName="Bob McParent" />
    </div>
  ),
};

export const MacUserCreateForm: Story = {
  ...props(Welcome.args!),
  render: () => (
    <div className="fixed inset-0 bg-slate-50">
      <CreateUserForm />
    </div>
  ),
};

export const MacUserCreateSuccess: Story = {
  ...props(Welcome.args!),
  render: () => (
    <div className="fixed inset-0 bg-slate-50">
      <PostCreateConfirm
        childName="Little Jimmy"
        username="littlejimmy"
        currentUserName="Bob McParent"
      />
    </div>
  ),
};

export const MacUserHappyPath: Story = props({
  ...Welcome.args,
  step: `macosUserAccountType`,
});

export const ConfirmGertrudeAcct: Story = props({
  ...Welcome.args,
  step: `confirmGertrudeAccount`,
});

export const NoGertrudeAcct: Story = props({
  ...Welcome.args,
  step: `noGertrudeAccount`,
});

export const GetConnectionCode: Story = props({
  ...Welcome.args,
  step: `getChildConnectionCode`,
});

export const ConnectChildIdle: Story = props({
  ...Welcome.args,
  step: `connectChild`,
});

export const ConnectChildOngoing: Story = props({
  ...Welcome.args,
  step: `connectChild`,
  connectChildRequest: { case: `ongoing` },
});

export const ConnectChildFailed: Story = props({
  ...Welcome.args,
  step: `connectChild`,
  connectChildRequest: { case: `failed` },
});

export const ConnectChildSuccess: Story = props({
  ...Welcome.args,
  step: `connectChild`,
  connectChildRequest: { case: `succeeded`, payload: `Little Jimmy` },
});

export const HowToUseGifs: Story = props({
  ...Welcome.args,
  step: `howToUseGifs`,
});

export const AllowNotificationsStart: Story = props({
  ...Welcome.args,
  step: `allowNotifications_start`,
});

export const AllowNotificationsGrant: Story = props({
  ...Welcome.args,
  step: `allowNotifications_grant`,
});

export const AllowNotificationsFailed: Story = props({
  ...Welcome.args,
  step: `allowNotifications_failed`,
});

export const AllowDiskAccessGrant: Story = props({
  ...Welcome.args,
  step: `allowFullDiskAccess_grantAndRestart`,
});

export const AllowDiskAccessFailed: Story = props({
  ...Welcome.args,
  step: `allowFullDiskAccess_failed`,
});

export const AllowDiskAccessSuccess: Story = props({
  ...Welcome.args,
  step: `allowFullDiskAccess_success`,
});

export const AllowDiskAccessGrantUpgrade: Story = props({
  ...Welcome.args,
  step: `allowFullDiskAccess_grantAndRestart`,
  isUpgrade: true,
});

export const AllowDiskAccessSuccessUpgrade: Story = props({
  ...Welcome.args,
  step: `allowFullDiskAccess_success`,
  isUpgrade: true,
});

export const AllowScreenshotsRequired: Story = props({
  ...Welcome.args,
  step: `allowScreenshots_required`,
});

export const AllowScreenshotsGrant: Story = props({
  ...Welcome.args,
  step: `allowScreenshots_grantAndRestart`,
});

export const AllowScreenshotsFailed: Story = props({
  ...Welcome.args,
  step: `allowScreenshots_failed`,
});

export const AllowScreenshotsSuccess: Story = props({
  ...Welcome.args,
  step: `allowScreenshots_success`,
});

export const AllowKeyloggingRequired: Story = props({
  ...Welcome.args,
  step: `allowKeylogging_required`,
});

export const AllowKeyloggingGrant: Story = props({
  ...Welcome.args,
  step: `allowKeylogging_grant`,
});

export const AllowKeyloggingFailed: Story = props({
  ...Welcome.args,
  step: `allowKeylogging_failed`,
});

export const InstallSysExtExplain: Story = props({
  ...Welcome.args,
  step: `installSysExt_explain`,
});

export const InstallSysExtAllowTrick: Story = props({
  ...Welcome.args,
  step: `installSysExt_trick`,
});

export const InstallSysExtAllowInstall: Story = props({
  ...Welcome.args,
  step: `installSysExt_allow`,
});

export const InstallSysExtFail: Story = props({
  ...Welcome.args,
  step: `installSysExt_failed`,
});

export const PermissionsComplete: Story = props({
  ...Welcome.args,
  step: `installSysExt_success_configPivot`,
});

export const OptOutOfFiltering: Story = props({
  ...Welcome.args,
  step: `optOutOfFiltering`,
});

export const ConfigureDowntime: Story = props({
  ...Welcome.args,
  step: `configureDowntime`,
});

export const AppKeySelectionIntro: Story = props({
  ...Welcome.args,
  step: `appKeySelection_intro`,
});

export const BlockApps: Story = props({
  ...Welcome.args,
  step: `appKeySelection_blockApps`,
  discoveredApps: STUB_APPS,
});

export const AllowInternetApps: Story = props({
  ...Welcome.args,
  step: `appKeySelection_allowInternet`,
  discoveredApps: STUB_APPS,
});

export const AboutPermittingWebsites: Story = props({
  ...Welcome.args,
  step: `aboutPermittingWebsites`,
});

export const MeetKeychains: Story = props({
  ...Welcome.args,
  step: `meetKeychains`,
});

export const SelectPublicKeychains: Story = props({
  ...Welcome.args,
  step: `selectPublicKeychains`,
  publicKeychains: STUB_PUBLIC_KEYCHAINS,
});

export const CustomKeychains: Story = props({
  ...Welcome.args,
  step: `customKeychains`,
});

export const CustomKeychainsWithDomains: Story = props({
  ...Welcome.args,
  step: `customKeychains`,
  customKeychainDomains: [`schoolportal.edu`, `kidsports.org`, `coolmathgames.com`],
});

export const CustomKeychainsOngoing: Story = props({
  ...Welcome.args,
  step: `customKeychains`,
  customKeychainDomains: [`schoolportal.edu`],
  createCustomKeychainRequest: { case: `ongoing` },
});

export const CustomKeychainsFailed: Story = props({
  ...Welcome.args,
  step: `customKeychains`,
  customKeychainDomains: [`schoolportal.edu`],
  createCustomKeychainRequest: { case: `failed`, error: `fake.typo` },
});

export const ExemptUsers: Story = props({
  ...Welcome.args,
  step: `exemptUsers`,
});

export const LocateMenuBarIcon: Story = props({
  ...Welcome.args,
  step: `locateMenuBarIcon`,
});

export const EasyMode: Story = props({
  ...Welcome.args,
  step: `encourageFilterSuspensions`,
});

export const AlwaysBlockedGroups: Story = props({
  ...Welcome.args,
  step: `alwaysBlockedGroups`,
  alwaysBlocked: {
    groups: ALWAYS_BLOCKED_GROUPS,
    preselected: [ADULT_CONTENT, MESSAGES_GIF, SPOTLIGHT_SEARCH],
  },
});

export const ViewHealthCheck: Story = props({
  ...Welcome.args,
  step: `viewHealthCheck`,
});

export const ScreenTimeConflict: Story = props({
  ...Welcome.args,
  step: `screenTimeConflict`,
});

export const Finish: Story = props({
  ...Welcome.args,
  step: `finish`,
});

export default meta;
