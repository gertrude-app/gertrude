import { Administrate } from '@macos/appviews';
import type { Meta, StoryObj } from '@storybook/react';
import type { ComponentProps as Wrapping } from 'react';
import { props } from '../story-helpers';
import AppWindow from './AppWindow';

const meta = {
  title: 'MacOS App/Administrate', // eslint-disable-line
  component: AppWindow<Wrapping<typeof Administrate>>,
  parameters: { layout: `centered` },
} satisfies Meta<typeof AppWindow<Wrapping<typeof Administrate>>>;

type Story = StoryObj<typeof meta>;

export const HomeChecksPassingLight: Story = props({
  width: 900,
  height: 530,
  wrapping: Administrate,
  props: {
    screen: `home`,
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
    userName: `Little Jimmy`,
    screenshotMonitoringEnabled: true,
    keystrokeMonitoringEnabled: false,
    releaseChannel: `stable`,
    quitting: false,
    filterSuspensionDurationInSeconds: `300`,
    emit: () => {},
    dispatch: () => {},
  },
});

export const HomeChecksPassingDark: Story = props({
  ...HomeChecksPassingLight.args,
  dark: true,
});

export const HomeAccountNeedsAttentionLight: Story = props({
  ...HomeChecksPassingLight.args,
  props: {
    ...HomeChecksPassingLight.args.props,
    healthCheck: {
      ...HomeChecksPassingLight.args.props.healthCheck,
      accountStatus: { case: `ok`, value: `needsAttention` },
    },
  },
});

export const HomeAccountNeedsAttentionDark: Story = props({
  ...HomeAccountNeedsAttentionLight.args,
  dark: true,
});

export const HomeAccountInactiveLight: Story = props({
  ...HomeChecksPassingLight.args,
  props: {
    ...HomeChecksPassingLight.args.props,
    healthCheck: {
      ...HomeChecksPassingLight.args.props.healthCheck,
      accountStatus: { case: `ok`, value: `inactive` },
    },
  },
});

export const HomeAccountInactiveDark: Story = props({
  ...HomeAccountInactiveLight.args,
  dark: true,
});

export const HomeChecksFailingLight: Story = props({
  ...HomeChecksPassingLight.args,
  props: {
    ...HomeChecksPassingLight.args.props,
    healthCheck: {
      ...HomeChecksPassingLight.args.props.healthCheck,
      screenshotMonitoringEnabled: false,
      notificationsSetting: `none`,
    },
    filterState: { case: `on` },
  },
});

export const HomeChecksFailingDark: Story = props({
  ...HomeChecksFailingLight.args,
  dark: true,
});

export const HealthCheckLoadingLight: Story = props({
  ...HomeChecksPassingLight.args,
  props: {
    ...HomeChecksPassingLight.args.props,
    screen: `healthCheck`,
    healthCheck: {},
  },
});

export const HealthCheckLoadingDark: Story = props({
  ...HealthCheckLoadingLight.args,
  dark: true,
});

export const HealthCheckFailingLight: Story = props({
  ...HealthCheckLoadingLight.args,
  props: {
    ...HealthCheckLoadingLight.args.props,
    screen: `healthCheck`,
    healthCheck: {
      latestAppVersion: { case: `ok`, value: `2.1.0` },
      filterStatus: {
        case: `installed`,
        version: `1.6.0`,
        numUserKeys: 0,
      },
      screenRecordingPermissionOk: false,
      keystrokeRecordingPermissionOk: false,
      macOsUserType: { case: `ok`, value: `admin` },
      notificationsSetting: `none`,
      accountStatus: { case: `ok`, value: `active` },
    },
    screenshotMonitoringEnabled: true,
    keystrokeMonitoringEnabled: true,
  },
});

export const HealthCheckFailingDark: Story = props({
  ...HealthCheckFailingLight.args,
  dark: true,
});

export const HealthCheckErrorLight: Story = props({
  ...HealthCheckLoadingLight.args,
  props: {
    ...HealthCheckLoadingLight.args.props,
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
  },
});

export const HealthCheckErrorDark: Story = props({
  ...HealthCheckErrorLight.args,
  dark: true,
});

export const ExemptUsersLight: Story = props({
  ...HomeChecksPassingLight.args,
  props: {
    ...HomeChecksPassingLight.args.props,
    exemptableUsers: {
      case: `ok`,
      value: [
        { id: 501, name: `Dad`, isExempt: true, isAdmin: true },
        { id: 503, name: `Big Suzy`, isExempt: false, isAdmin: false },
      ],
    },
    screen: `exemptUsers`,
  },
});

export const ExemptUsersDark: Story = props({
  ...ExemptUsersLight.args,
  dark: true,
});

export const ExemptUsersErrorLight: Story = props({
  ...ExemptUsersLight.args,
  props: {
    ...ExemptUsersLight.args.props,
    exemptableUsers: { case: `error` },
  },
});

export const ExemptUsersErrorDark: Story = props({
  ...ExemptUsersErrorLight.args,
  dark: true,
});

export const Advanced: Story = props({
  ...HomeChecksPassingLight.args,
  props: {
    ...HomeChecksPassingLight.args.props,
    screen: `advanced`,
    advanced: {
      pairqlEndpointDefault: `https://api.getrude.app/pairql`,
      websocketEndpointDefault: `https://api.getrude.app/websocket-app`,
      appcastEndpointDefault: `https://api.getrude.app/appcast.xml`,
      appVersions: {
        '2.1.1': `2.1.1`,
        '2.2.0': `2.2.0 (beta)`,
      },
    },
  },
});

export default meta;
