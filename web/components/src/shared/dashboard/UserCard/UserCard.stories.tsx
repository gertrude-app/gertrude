import { ComponentStory, ComponentMeta } from '@storybook/react';

import UserCard from './UserCard';

export default {
  title: `UserCard`,
  component: UserCard,
} as ComponentMeta<typeof UserCard>;

const Template: ComponentStory<typeof UserCard> = (args) => <UserCard {...args} />;

export const Standard = Template.bind({});
Standard.args = {
  devices: [{ title: `14" Macbook Pro`, status: `online` }],
  title: `John Doe`,
  keychains: 4,
  keys: 57,
  screenshots: true,
  keystrokes: false,
};

export const Empty = Template.bind({});
Empty.args = {
  devices: [],
  title: `John Doe`,
  keychains: 0,
  keys: 0,
  screenshots: false,
  keystrokes: false,
};

export const Full = Template.bind({});
Full.args = {
  devices: [
    { title: `13" MacBook Air`, status: `online` },
    { title: `Mac Mini`, status: `offline` },
    { title: `iMac`, status: `offline` },
  ],
  title: `John Doe`,
  keychains: 32,
  keys: 1546,
  screenshots: true,
  keystrokes: true,
};
