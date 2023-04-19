import { EmptyState } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Dashboard/Core/EmptyState', // eslint-disable-line
  component: EmptyState,
} satisfies Meta<typeof EmptyState>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs/350,md/350
export const Default: Story = props({
  heading: `No burgers`,
  secondaryText: `Let's make some!`,
  buttonText: `Make a burger`,
  icon: `burger`,
  action: () => {},
});

// @screenshot: xs/350,md/350
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

// @screenshot: xs/350
export const Violet: Story = props({
  ...Default.args,
  violet: true,
});

export default meta;
