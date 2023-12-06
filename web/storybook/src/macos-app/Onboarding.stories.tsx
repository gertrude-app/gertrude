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
  windowOpen: true,
  os: `venturaOrLater`,
  step: `welcome`,
  connectChildRequest: { case: `idle` },
  screenRecordingPermissionGranted: false,
  keyloggingPermissionGranted: false,
  currentUser: { id: 502, name: `Suzy`, isAdmin: false },
  users: [
    { id: 503, name: `Little Jimmy`, isAdmin: false },
    { id: 501, name: `Bob McParent`, isAdmin: true },
    { id: 502, name: `Suzy`, isAdmin: false },
  ],
  connectionCode: ``,
  didResume: false,
  receivedAppState: true,
});

export const AppNotInApplicationsDir: Story = props({
  ...Welcome.args,
  step: `appNotInApplicationsDir`,
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
  users: [
    { id: 501, name: `Bob McParent`, isAdmin: true },
    { id: 504, name: `Betsy`, isAdmin: true },
  ],
});

export const MacUserBad: Story = props({
  ...Welcome.args,
  step: `macosUserAccountType`,
  currentUser: { id: 501, name: `Bob McParent`, isAdmin: true },
  users: [{ id: 501, name: `Bob McParent`, isAdmin: true }],
});

export const MacUserChoose: Story = props({
  ...MacUserBad.args,
  userRemediationStep: `choose`,
  users: [
    { id: 501, name: `Bob McParent`, isAdmin: true },
    { id: 502, name: `Sally McMom`, isAdmin: true },
    { id: 502, name: `Little Jimmy`, isAdmin: false },
  ],
});

export const MacUserTutorialCreate: Story = props({
  ...MacUserBad.args,
  userRemediationStep: `create`,
});

export const MacUserTutorialSwitch: Story = props({
  ...MacUserBad.args,
  userRemediationStep: `switch`,
});

export const MacUserTutorialDemote: Story = props({
  ...MacUserBad.args,
  userRemediationStep: `demote`,
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

export const HowToUseGertrude: Story = props({
  ...Welcome.args,
  step: `howToUseGertrude`,
});

export const Finish: Story = props({
  ...Welcome.args,
  step: `finish`,
});

export default meta;
