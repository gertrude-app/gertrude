import CTABlock from '@site/components/CTABlock';
import type { Meta, StoryObj } from '@storybook/react';

const meta = {
  title: 'Site/CTABlock',
  component: CTABlock,
  parameters: {
    layout: `fullscreen`,
  },
} satisfies Meta<typeof CTABlock>;

type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export default meta;
