import { EmptyState } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Dashboard/Core/EmptyState', // eslint-disable-line
  component: EmptyState,
} satisfies Meta<typeof EmptyState>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  heading: `No burgers`,
  secondaryText: `Let's make some!`,
  buttonText: `Make a burger`,
  icon: `burger`,
  action: () => {},
});

export const WithSecondaryButton: Story = props({
  heading: `No burgers`,
  secondaryText: `Let's make some!`,
  buttonText: `Make a burger`,
  icon: `burger`,
  action: () => {},
  secondaryButton: {
    text: `Or not`,
    action: () => {},
    icon: `times`,
  },
});

export const Violet: Story = props({
  ...Default.args,
  violet: true,
});

export default meta;
