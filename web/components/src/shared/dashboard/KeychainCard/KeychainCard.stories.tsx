import { ComponentStory, ComponentMeta } from '@storybook/react';

import KeychainCard from './KeychainCard';

export default {
  title: `KeychainCard`,
  component: KeychainCard,
} as ComponentMeta<typeof KeychainCard>;

const Template: ComponentStory<typeof KeychainCard> = (args) => (
  <KeychainCard {...args} />
);

export const Default = Template.bind({});
