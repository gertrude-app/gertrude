import { Logo } from '@shared/components';
import type { StoryObj, Meta } from '@storybook/react';

const meta = {
  title: 'Shared/Logo', // eslint-disable-line
  component: Logo,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Logo>;

type Story = StoryObj<typeof meta>;

export const Default: Story = {
  decorators: [
    (Story) => (
      <div className="py-8 flex justify-center">
        <Story />
      </div>
    ),
  ],
};

export const DefaultIconOnly: Story = {
  decorators: Default.decorators,
  args: {
    type: `default`,
    iconOnly: true,
    size: 90,
  },
};

export const Inverted: Story = {
  decorators: [
    (Story) => (
      <div className="py-8 bg-violet-500 flex justify-center">
        <Story />
      </div>
    ),
  ],
  args: {
    type: `inverted`,
    iconOnly: false,
  },
};

export const InvertedIconOnly: Story = {
  decorators: Inverted.decorators,
  args: {
    type: `inverted`,
    iconOnly: true,
    size: 90,
  },
};

export default meta;
