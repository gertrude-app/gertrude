import { SelectableListItem } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Forms/SelectableListItem', // eslint-disable-line
  component: SelectableListItem,
} satisfies Meta<typeof SelectableListItem>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  title: `Lorem ipsum dolor`,
  description: `Lorem ipsum dolor sit amet consectetur adipisicing elit. Aperiam in, quam, modi quibusdam cupiditate labore illum dolorum doloribus, voluptates veritatis quis laborum.`,
  selected: false,
  badges: [],
});

export const Selected: Story = props({
  ...Default.args,
  selected: true,
});

export const WithBadge: Story = props({
  ...Default.args,
  badges: [{ text: `Best option`, color: `green` }],
});

export const SelectedWithBadge: Story = props({
  ...WithBadge.args,
  selected: true,
});

export const ManyBadges: Story = props({
  ...Default.args,
  badges: [
    { text: `Best option`, color: `green` },
    { text: `Super safe`, color: `blue` },
    { text: `Extremely dangerous`, color: `red` },
  ],
});

export const SelectedWithManyBadges: Story = props({
  ...ManyBadges.args,
  selected: true,
});

export default meta;
