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

export const LightModeChecksPassing: Story = props({
  width: 900,
  height: 530,
  wrapping: Administrate,
  props: {
    healthCheck: {
      appVersion: `0.5.0`,
      mostRecentAppVersion: `0.5.0`,
      filterVersion: `0.5.0`,
      mostRecentFilterVersion: `0.5.0`,
      screenRecordingPermission: true,
      keystrokeRecordingPermission: true,
      isAdministrator: false,
      filterToAppCommunicationVerified: true,
      notificationSetting: `alert`,
      accountStatus: `active`,
      keysLoaded: 23,
    },
    filterStatus: `on`,
    userName: `Little Jimmy`,
    screenshotMonitoringEnabled: true,
    keystrokeMonitoringEnabled: false,
  },
});

export const LightModeChecksFailing: Story = props({
  ...LightModeChecksPassing.args,
  props: {
    ...LightModeChecksPassing.args.props,
    healthCheck: {
      ...LightModeChecksPassing.args.props.healthCheck,
      appVersion: `0.4.12`,
      screenRecordingPermission: false,
      notificationSetting: `banners`,
    },
    filterStatus: `suspended`,
  },
});

export const DarkModeChecksPassing: Story = props({
  ...LightModeChecksPassing.args,
  dark: true,
});

export const DarkModeChecksFailing: Story = props({
  ...LightModeChecksFailing.args,
  dark: true,
});

export default meta;
