import { SelectMenu } from '@shared/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Shared/SelectMenu', // eslint-disable-line
  component: SelectMenu,
} satisfies Meta<typeof SelectMenu>;

type Story = StoryObj<typeof meta>;

export const Large: Story = props({
  options: [
    { value: `1`, display: `Do this` },
    { value: `2`, display: `Do that` },
    { value: `3`, display: `Do the other thing` },
  ],
  selectedOption: `Do this`,
});

export const Medium: Story = props({
  ...Large.args,
  size: `medium`,
});

export const Small: Story = props({
  ...Large.args,
  size: `small`,
});

export default meta;
