import { Administrate } from '@macos/appviews';
import type { Meta, StoryObj } from '@storybook/react';
import { appWindow, props } from '../story-helpers';

const meta = {
  title: 'MacOS App/Administrate', // eslint-disable-line
  component: Administrate,
  parameters: appWindow(900, 660),
} satisfies Meta<typeof Administrate>;

type Story = StoryObj<typeof meta>;

export const Actions: Story = props({
  screen: `actions`,
  windowOpen: true,
  healthCheck: {
    latestAppVersion: { case: `ok`, value: `2.0.0` },
    filterStatus: {
      case: `installed`,
      version: `2.0.0`,
      numUserKeys: 42,
    },
    screenRecordingPermissionOk: true,
    keystrokeRecordingPermissionOk: true,
    macOsUserType: { case: `ok`, value: `standard` },
    notificationsSetting: `alert`,
    accountStatus: { case: `ok`, value: `active` },
  },
  installedAppVersion: `2.0.0`,
  filterState: { case: `on` },
  user: {
    name: `Little Jimmy`,
    screenshotMonitoringEnabled: true,
    keystrokeMonitoringEnabled: false,
  },
  releaseChannel: `stable`,
  quitting: false,
  filterSuspensionDurationInSeconds: `300`,
  dangerZoneModal: `hidden`,
  availableAppUpdate: undefined,
  emit: () => {},
  dispatch: () => {},
});

export const ActionsNoUserOrFilter: Story = props({
  ...Actions.args,
  user: undefined,
  filterState: { case: `off` },
});

export const ActionsUpdateAvailable: Story = props({
  ...Actions.args,
  availableAppUpdate: { semver: `4.2.1`, required: false },
});

export const ActionsUpdateRequired: Story = props({
  ...Actions.args,
  availableAppUpdate: { semver: `4.2.1`, required: true },
});

export const ActionsBetaChannel: Story = props({
  ...Actions.args,
  releaseChannel: `beta`,
});

export const ActionsModalOpen: Story = props({
  ...Actions.args,
  dangerZoneModal: `stopFilter`,
});

export const ActionsAccountInactive: Story = props({
  ...Actions.args,
  healthCheck: {
    ...Actions.args.healthCheck,
    accountStatus: { case: `ok`, value: `inactive` },
  },
});

export const HealthCheckLoading: Story = props({
  ...Actions.args,
  screen: `healthCheck`,
  healthCheck: {},
});

export const HealthCheckFailing: Story = props({
  ...HealthCheckLoading.args,
  screen: `healthCheck`,
  healthCheck: {
    latestAppVersion: { case: `ok`, value: `2.1.0` },
    filterStatus: { case: `communicationBroken`, repairing: false },
    screenRecordingPermissionOk: false,
    keystrokeRecordingPermissionOk: false,
    macOsUserType: { case: `ok`, value: `admin` },
    notificationsSetting: `none`,
    accountStatus: { case: `ok`, value: `active` },
  },
  screenshotMonitoringEnabled: true,
  keystrokeMonitoringEnabled: true,
});

export const HealthCheckError: Story = props({
  ...HealthCheckLoading.args,
  screen: `healthCheck`,
  healthCheck: {
    latestAppVersion: { case: `error` },
    filterStatus: { case: `unexpected` },
    screenRecordingPermissionOk: false,
    keystrokeRecordingPermissionOk: false,
    macOsUserType: { case: `error`, message: `Check the specs on the rotary girder` },
    notificationsSetting: `none`,
    accountStatus: { case: `error` },
  },
});

export const ExemptUsers: Story = props({
  ...Actions.args,
  screen: `exemptUsers`,
  exemptableUsers: {
    case: `ok`,
    value: [
      { id: 501, name: `Dad`, isExempt: true, isAdmin: true },
      { id: 503, name: `Big Suzy`, isExempt: false, isAdmin: false },
    ],
  },
});

export const ExemptUsersError: Story = props({
  ...ExemptUsers.args,
  exemptableUsers: { case: `error` },
});

export const Advanced: Story = props({
  ...Actions.args,
  screen: `advanced`,
  advanced: {
    pairqlEndpointDefault: `https://api.getrude.app/pairql`,
    websocketEndpointDefault: `https://api.getrude.app/websocket-app`,
    appcastEndpointDefault: `https://api.getrude.app/appcast.xml`,
    webviewDebugging: false,
    appVersions: {
      '2.1.1': `2.1.1`,
      '2.2.0': `2.2.0 (beta)`,
    },
  },
});

export default meta;
