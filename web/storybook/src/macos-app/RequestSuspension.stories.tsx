import { RequestSuspension } from '@macos/appviews';
import type { Meta, StoryObj } from '@storybook/react';
import type { ComponentProps as Wrapping } from 'react';
import { props } from '../story-helpers';
import AppWindow from './AppWindow';

const meta = {
  title: 'MacOS App/RequestSuspension', // eslint-disable-line
  component: AppWindow<Wrapping<typeof RequestSuspension>>,
  parameters: { layout: `centered` },
} satisfies Meta<typeof AppWindow<Wrapping<typeof RequestSuspension>>>;

type Story = StoryObj<typeof meta>;

export const LightMode: Story = props({
  width: 600,
  height: 400,
  wrapping: RequestSuspension,
  props: {},
});

export const DarkMode: Story = props({
  ...LightMode.args,
  dark: true,
});

export default meta;
