import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeychainCard from './KeychainCard';

export default {
  title: `Dashboard/Keychains/KeychainCard`,
  component: KeychainCard,
} as ComponentMeta<typeof KeychainCard>;

const Template: ComponentStory<typeof KeychainCard> = (args) => (
  <KeychainCard {...args} />
);

export const Shared = Template.bind({});
Shared.args = {
  name: `HTC`,
  keys: 43,
  isPublic: true,
  description: `Lorem ipsum dolor sit amet consectetur, adipisicing elit. Ipsum laboriosam aperiam quasi blanditiis.`,
  onRemove: () => {},
};

export const Private = Template.bind({});
Private.args = {
  ...Shared.args,
  isPublic: false,
};

export const Editable = Template.bind({});
Editable.args = {
  ...Shared.args,
  isPublic: false,
  editUrl: `/keychains/1`,
};

export const SmallPrivate = Template.bind({});
SmallPrivate.args = {
  ...Shared.args,
  isPublic: false,
  small: true,
  selectable: true,
};

export const SmallPublic = Template.bind({});
SmallPublic.args = {
  ...Shared.args,
  isPublic: true,
  small: true,
  selectable: true,
};

export const SmallSelected = Template.bind({});
SmallSelected.args = {
  ...Shared.args,
  isPublic: true,
  small: true,
  selected: true,
};

export const LargeSelected = Template.bind({});
LargeSelected.args = {
  ...Shared.args,
  isPublic: true,
  selected: true,
};
