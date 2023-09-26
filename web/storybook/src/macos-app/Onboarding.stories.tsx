import { Onboarding } from '@macos/appviews';
import type { StoryObj, Meta } from '@storybook/react';
import { props, appWindow } from '../story-helpers';

const meta = {
  title: 'MacOS App/Onboarding', // eslint-disable-line
  component: Onboarding,
  parameters: appWindow(900, 700),
} satisfies Meta<typeof Onboarding>;

type Story = StoryObj<typeof meta>;

export const Welcome: Story = props({
  os: `venturaOrLater`,
  step: `welcome`,
  connectChildRequest: { state: `idle` },
  screenRecordingPermissionGranted: false,
  keyloggingPermissionGranted: false,
  macOSUser: {
    current: { id: 502, name: `Suzy`, isAdmin: false },
    list: [
      { id: 501, name: `Bob McParent`, isAdmin: true },
      { id: 502, name: `Suzy`, isAdmin: false },
    ],
  },
  connectionCode: ``,
});

export const ConfirmGertrudeAcct: Story = props({
  ...Welcome.args,
  step: `confirmGertrudeAccount`,
});

export const NoGertrudeAcct: Story = props({
  ...Welcome.args,
  step: `noGertrudeAccount`,
});

export const MacUserGood: Story = props({
  ...Welcome.args,
  step: `macosUserAccountType`,
});

export const MacUserGood2: Story = props({
  ...Welcome.args,
  step: `macosUserAccountType`,
  macOSUser: {
    ...Welcome.args.macOSUser,
    list: [
      { id: 501, name: `Bob McParent`, isAdmin: true },
      { id: 504, name: `Betsy`, isAdmin: true },
    ],
  },
});

export const MacUserBad: Story = props({
  ...Welcome.args,
  step: `macosUserAccountType`,
  macOSUser: {
    current: { id: 501, name: `Bob McParent`, isAdmin: true },
    list: [{ id: 501, name: `Bob McParent`, isAdmin: true }],
  },
});

export const MacUserChoose: Story = props({
  ...MacUserBad.args,
  macOSUser: {
    ...MacUserBad.args.macOSUser,
    remediationStep: `choose`,
    current: { id: 501, name: `Bob McParent`, isAdmin: true },
    list: [
      { id: 501, name: `Bob McParent`, isAdmin: true },
      { id: 502, name: `Sally McMom`, isAdmin: true },
      { id: 502, name: `Little Jimmy`, isAdmin: false },
    ],
  },
});

export const MacUserTutorialCreate: Story = props({
  ...MacUserBad.args,
  macOSUser: {
    ...MacUserBad.args.macOSUser,
    remediationStep: `create`,
  },
});

export const MacUserTutorialSwitch: Story = props({
  ...MacUserBad.args,
  macOSUser: {
    ...MacUserBad.args.macOSUser,
    remediationStep: `switch`,
  },
});

export const MacUserTutorialDemote: Story = props({
  ...MacUserBad.args,
  macOSUser: {
    ...MacUserBad.args.macOSUser,
    remediationStep: `demote`,
  },
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
  connectChildRequest: { state: `ongoing` },
});

export const ConnectChildFailed: Story = props({
  ...Welcome.args,
  step: `connectChild`,
  connectChildRequest: { state: `failed` },
});

export const ConnectChildSuccess: Story = props({
  ...Welcome.args,
  step: `connectChild`,
  connectChildRequest: { state: `succeeded`, payload: `Little Jimmy` },
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

export const AllowScreenshotsRequired: Story = props({
  ...Welcome.args,
  step: `allowScreenshots_required`,
});

export const AllowScreenshotsOpenSettings: Story = props({
  ...Welcome.args,
  step: `allowScreenshots_openSysSettings`,
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

export const AllowKeyloggingOpenSettings: Story = props({
  ...Welcome.args,
  step: `allowKeylogging_openSysSettings`,
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

export const InstallSysExtStart: Story = props({
  ...Welcome.args,
  step: `installSysExt_start`,
});

export const InstallSysExtAllowInstall: Story = props({
  ...Welcome.args,
  step: `installSysExt_allowInstall`,
});

export const InstallSysExtFail: Story = props({
  ...Welcome.args,
  step: `installSysExt_failed`,
});

export const InstallSysExtSuccess: Story = props({
  ...Welcome.args,
  step: `installSysExt_success`,
});

export const LocateMenuBarIcon: Story = props({
  ...Welcome.args,
  step: `locateMenuBarIcon`,
});

export const ViewHealthCheck: Story = props({
  ...Welcome.args,
  step: `viewHealthCheck`,
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
