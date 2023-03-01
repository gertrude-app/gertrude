import { RequestSuspension } from '@macos/appviews';
import type { ComponentMeta, ComponentStory } from '@storybook/react';
import AppWindow from './AppWindow';

export default {
  title: 'MacOSApp/RequestSuspension', // eslint-disable-line
  component: RequestSuspension,
  parameters: {
    layout: `centered`,
  },
} as ComponentMeta<typeof RequestSuspension>;

const LightTemplate: ComponentStory<typeof RequestSuspension> = (args) => (
  <AppWindow width={600} height={400}>
    <RequestSuspension {...args} />
  </AppWindow>
);
export const LightMode = LightTemplate.bind({});
LightMode.args = {};

const DarkTemplate: ComponentStory<typeof RequestSuspension> = (args) => (
  <AppWindow width={600} height={400} dark>
    <RequestSuspension {...args} />
  </AppWindow>
);
export const DarkMode = DarkTemplate.bind({});
DarkMode.args = {};
