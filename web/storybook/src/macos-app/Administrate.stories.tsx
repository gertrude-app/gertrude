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
      filterData: {
        case: `ok`,
        value: { version: `2.0.0`, numKeys: 42 },
      },
      screenRecordingPermissionOk: true,
      keystrokeRecordingPermissionOk: true,
      macOsUserType: { case: `ok`, value: `standard` },
      notificationsPermission: `alert`,
      accountStatus: { case: `ok`, value: `active` },
    },
    installedAppVersion: `2.0.0`,
    filterState: `on`,
    userName: `Little Jimmy`,
    screenshotMonitoringEnabled: true,
    keystrokeMonitoringEnabled: false,
    emit: () => {},
    dispatch: () => {},
  },
});

export const HomeChecksPassingDark: Story = props({
  ...HomeChecksPassingLight.args,
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
      filterData: {
        case: `ok`,
        value: { version: `1.6.0`, numKeys: 0 },
      },
      screenRecordingPermissionOk: false,
      keystrokeRecordingPermissionOk: false,
      macOsUserType: { case: `ok`, value: `admin` },
      notificationsPermission: `none`,
      accountStatus: { case: `ok`, value: `inactive` },
    },
    screenshotMonitoringEnabled: true,
    keystrokeMonitoringEnabled: true,
  },
});

export const HealthCheckFailingDark: Story = props({
  ...HealthCheckFailingLight.args,
  dark: true,
});

export const HomeChecksFailingLight: Story = props({
  ...HomeChecksPassingLight.args,
  props: {
    ...HomeChecksPassingLight.args.props,
    healthCheck: {
      ...HomeChecksPassingLight.args.props.healthCheck,
      screenshotMonitoringEnabled: false,
      notificationsPermission: `none`,
    },
    filterState: `suspended`,
  },
});

export const HomeChecksFailingDark: Story = props({
  ...HomeChecksFailingLight.args,
  dark: true,
});

export const HealthCheckErrorLight: Story = props({
  ...HealthCheckLoadingLight.args,
  props: {
    ...HealthCheckLoadingLight.args.props,
    screen: `healthCheck`,
    healthCheck: {
      latestAppVersion: { case: `error` },
      filterData: { case: `error` },
      screenRecordingPermissionOk: false,
      keystrokeRecordingPermissionOk: false,
      macOsUserType: { case: `error`, message: `Check the specs on the rotary girder` },
      notificationsPermission: `none`,
      accountStatus: { case: `error` },
    },
  },
});

export const HealthCheckErrorDark: Story = props({
  ...HealthCheckErrorLight.args,
  dark: true,
});

export default meta;
