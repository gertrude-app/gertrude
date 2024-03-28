import TestimonialsBlock from '@site/components/TestimonialsBlock';
import type { StoryObj, Meta } from '@storybook/react';

const meta = {
  title: 'Site/TestimonialsBlock', // eslint-disable-line
  component: TestimonialsBlock,
  parameters: {
    layout: `fullscreen`,
  },
} satisfies Meta<typeof TestimonialsBlock>;

type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export default meta;
