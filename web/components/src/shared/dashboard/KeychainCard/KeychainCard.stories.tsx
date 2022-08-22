import { ComponentStory, ComponentMeta } from '@storybook/react';

import KeychainCard from './KeychainCard';

export default {
  title: `Dashboard/Users/KeychainCard`,
  component: KeychainCard,
} as ComponentMeta<typeof KeychainCard>;

const Template: ComponentStory<typeof KeychainCard> = (args) => (
  <KeychainCard {...args} />
);

export const Shared = Template.bind({});
Shared.args = {
  name: `HTC`,
  keys: 43,
  shared: true,
};

export const Private = Template.bind({});
Private.args = {
  name: `HTC`,
  keys: 43,
  shared: false,
};
