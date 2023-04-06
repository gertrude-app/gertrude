import { Administrate } from '@macos/appviews';
import type { ComponentMeta, StoryFn } from '@storybook/react';
import AppWindow from './AppWindow';

export default {
  title: 'MacOS App/Administrate', // eslint-disable-line
  component: Administrate,
  parameters: {
    layout: `centered`,
  },
} as ComponentMeta<typeof Administrate>;

const LightTemplate: StoryFn<typeof Administrate> = (args) => (
  <AppWindow width={900} height={530}>
    <Administrate {...args} />
  </AppWindow>
);

export const LightModeChecksPassing = LightTemplate.bind({});
LightModeChecksPassing.args = {
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
};

export const LightModeChecksFailing = LightTemplate.bind({});
LightModeChecksFailing.args = {
  ...LightModeChecksPassing.args,
  healthCheck: {
    ...LightModeChecksPassing.args.healthCheck!,
    appVersion: `0.4.12`,
    screenRecordingPermission: false,
    notificationSetting: `banners`,
  },
  filterStatus: `suspended`,
};

const DarkTemplate: StoryFn<typeof Administrate> = (args) => (
  <AppWindow width={900} height={530} dark>
    <Administrate {...args} />
  </AppWindow>
);

export const DarkModeChecksPassing = DarkTemplate.bind({});
DarkModeChecksPassing.args = {
  ...LightModeChecksPassing.args,
};
export const DarkModeChecksFailing = DarkTemplate.bind({});
DarkModeChecksFailing.args = {
  ...LightModeChecksFailing.args,
};
