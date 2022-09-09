import { ComponentStory, ComponentMeta } from '@storybook/react';
import SelectableListItem from './SelectableListItem';

export default {
  title: `Dashboard/Core/SelectableListItem`,
  component: SelectableListItem,
} as ComponentMeta<typeof SelectableListItem>;

const Template: ComponentStory<typeof SelectableListItem> = (args) => (
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
  title: `Lorem ipsum dolor`,
  description: `Lorem ipsum dolor sit amet consectetur adipisicing elit. Aperiam in, quam, modi quibusdam cupiditate labore illum dolorum doloribus, voluptates veritatis quis laborum.`,
  selected: true,
  badges: [],
};

export const WithBadge = Template.bind({});
WithBadge.args = {
  title: `Lorem ipsum dolor`,
  description: `Lorem ipsum dolor sit amet consectetur adipisicing elit. Aperiam in, quam, modi quibusdam cupiditate labore illum dolorum doloribus, voluptates veritatis quis laborum.`,
  selected: false,
  badges: [{ text: `Best option`, color: `green` }],
};

export const SelectedWithBadge = Template.bind({});
SelectedWithBadge.args = {
  title: `Lorem ipsum dolor`,
  description: `Lorem ipsum dolor sit amet consectetur adipisicing elit. Aperiam in, quam, modi quibusdam cupiditate labore illum dolorum doloribus, voluptates veritatis quis laborum.`,
  selected: true,
  badges: [{ text: `Best option`, color: `green` }],
};

export const ManyBadges = Template.bind({});
ManyBadges.args = {
  title: `Lorem ipsum dolor`,
  description: `Lorem ipsum dolor sit amet consectetur adipisicing elit. Aperiam in, quam, modi quibusdam cupiditate labore illum dolorum doloribus, voluptates veritatis quis laborum.`,
  selected: false,
  badges: [
    { text: `Best option`, color: `green` },
    { text: `Super safe`, color: `blue` },
    { text: `Extremely dangerous`, color: `red` },
  ],
};

export const SelectedWithManyBadges = Template.bind({});
SelectedWithManyBadges.args = {
  title: `Lorem ipsum dolor`,
  description: `Lorem ipsum dolor sit amet consectetur adipisicing elit. Aperiam in, quam, modi quibusdam cupiditate labore illum dolorum doloribus, voluptates veritatis quis laborum.`,
  selected: true,
  badges: [
    { text: `Best option`, color: `green` },
    { text: `Super safe`, color: `blue` },
    { text: `Extremely dangerous`, color: `red` },
  ],
};
