import { SelectableListItem } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Forms/SelectableListItem', // eslint-disable-line
  component: SelectableListItem,
} as ComponentMeta<typeof SelectableListItem>;

const Template: StoryFn<typeof SelectableListItem> = (args) => (
  <SelectableListItem {...args} />
);

export const Default = Template.bind({});
Default.args = {
  title: `Lorem ipsum dolor`,
  description: `Lorem ipsum dolor sit amet consectetur adipisicing elit. Aperiam in, quam, modi quibusdam cupiditate labore illum dolorum doloribus, voluptates veritatis quis laborum.`,
  selected: false,
  badges: [],
};

export const Selected = Template.bind({});
Selected.args = {
  ...Default.args,
  selected: true,
};

export const WithBadge = Template.bind({});
WithBadge.args = {
  ...Default.args,
  badges: [{ text: `Best option`, color: `green` }],
};

export const SelectedWithBadge = Template.bind({});
SelectedWithBadge.args = {
  ...WithBadge.args,
  selected: true,
};

export const ManyBadges = Template.bind({});
ManyBadges.args = {
  ...Default.args,
  badges: [
    { text: `Best option`, color: `green` },
    { text: `Super safe`, color: `blue` },
    { text: `Extremely dangerous`, color: `red` },
  ],
};

export const SelectedWithManyBadges = Template.bind({});
SelectedWithManyBadges.args = {
  ...ManyBadges.args,
  selected: true,
};
