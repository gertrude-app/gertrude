import PeaceOfMindForParentsBlock from '@site/components/PeaceOfMindForParentsBlock';
import type { Meta, StoryObj } from '@storybook/react';

const meta = {
  title: 'Site/PeaceOfMindForParentsBlock',
  component: PeaceOfMindForParentsBlock,
  parameters: {
    layout: `fullscreen`,
  },
} satisfies Meta<typeof PeaceOfMindForParentsBlock>;

type Story = StoryObj<typeof meta>;

export const Default: Story = {};

export default meta;
