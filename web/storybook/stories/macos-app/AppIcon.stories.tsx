import { AppIcon } from '@shared/components';
import type { Meta, StoryObj } from '@storybook/react';

const meta = {
  title: 'MacOS App/AppIcon', // eslint-disable-line
  component: AppIcon,
  parameters: {
    layout: `centered`,
  },
} satisfies Meta<typeof AppIcon>;

type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export default meta;
