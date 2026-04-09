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
  blockedBundleIds: [],
  createAppKeysRequest: { case: `idle` },
  emit: () => {},
  dispatch: () => {},
});

export const WrongInstallDir: Story = props({
  ...Welcome.args,
  step: `wrongInstallDir`,
});

export const ConfirmGertrudeAcct: Story = props({
  ...Welcome.args,
  step: `confirmGertrudeAccount`,
});

export const NoGertrudeAcct: Story = props({
  ...Welcome.args,
  step: `noGertrudeAccount`,
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

export const AllowDiskAccessSuccess: Story = props({
  ...Welcome.args,
  step: `allowFullDiskAccess_success`,
});

export const AllowDiskAccessFailed: Story = props({
  ...Welcome.args,
  step: `allowFullDiskAccess_failed`,
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

export const AllowScreenshotsSuccess: Story = props({
  ...Welcome.args,
  step: `allowScreenshots_success`,
});

export const AllowScreenshotsFailed: Story = props({
  ...Welcome.args,
  step: `allowScreenshots_failed`,
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

export const InstallSysExtSuccess: Story = props({
  ...Welcome.args,
  step: `installSysExt_success`,
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

export const OptOutOfFiltering: Story = props({
  ...Welcome.args,
  step: `optOutOfFiltering`,
});

export const ConfigureDowntime: Story = props({
  ...Welcome.args,
  step: `configureDowntime`,
});

export const ScreenTimeConflict: Story = props({
  ...Welcome.args,
  step: `screenTimeConflict`,
});

export const ExemptUsers: Story = props({
  ...Welcome.args,
  step: `exemptUsers`,
});

export const LocateMenuBarIcon: Story = props({
  ...Welcome.args,
  step: `locateMenuBarIcon`,
});

export const ViewHealthCheck: Story = props({
  ...Welcome.args,
  step: `viewHealthCheck`,
});

export const EasyMode: Story = props({
  ...Welcome.args,
  step: `encourageFilterSuspensions`,
});

export const HowToUseGertrude: Story = props({
  ...Welcome.args,
  step: `howToUseGertrude`,
});

export const Finish: Story = props({
  ...Welcome.args,
  step: `finish`,
});

export default meta;
