import FeaturesBlock from 'site/components/FeaturesBlock';
import type { StoryObj, Meta } from '@storybook/react';

const meta = {
  title: 'Site/FeaturesBlock', // eslint-disable-line
  component: FeaturesBlock,
  parameters: {
    layout: `fullscreen`,
  },
} satisfies Meta<typeof FeaturesBlock>;

type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export default meta;
