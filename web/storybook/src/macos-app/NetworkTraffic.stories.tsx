import { NetworkTraffic } from '@macos/appviews';
import type { Meta, StoryObj } from '@storybook/react';
import type { ComponentProps as Wrapping } from 'react';
import { props } from '../story-helpers';
import AppWindow from './AppWindow';

const meta = {
  title: 'MacOS App/NetworkTraffic', // eslint-disable-line
  component: AppWindow<Wrapping<typeof NetworkTraffic>>,
  parameters: { layout: `centered` },
} satisfies Meta<typeof AppWindow<Wrapping<typeof NetworkTraffic>>>;

type Story = StoryObj<typeof meta>;

export const LightMode: Story = props({
  width: 900,
  height: 600,
  wrapping: NetworkTraffic,
  props: {},
});

export const DarkMode: Story = props({
  ...LightMode.args,
  dark: true,
});

export default meta;
