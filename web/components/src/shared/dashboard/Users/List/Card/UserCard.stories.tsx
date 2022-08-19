import { ComponentStory, ComponentMeta } from '@storybook/react';

import UserCard from './UserCard';

export default {
  title: `Dashboard/Users/List/Card`,
  component: UserCard,
} as ComponentMeta<typeof UserCard>;

const Template: ComponentStory<typeof UserCard> = (args) => <UserCard {...args} />;

export const Standard = Template.bind({});
Standard.args = {
  devices: [{ id: `1`, icon: `laptop`, model: `14" Macbook Pro`, status: `online` }],
  name: `John Doe`,
  numKeychains: 4,
  numKeys: 57,
  screenshotsEnabled: true,
  keystrokesEnabled: false,
};

export const Empty = Template.bind({});
Empty.args = {
  devices: [],
  name: `John Doe`,
  numKeychains: 0,
  numKeys: 0,
  screenshotsEnabled: false,
  keystrokesEnabled: false,
};

export const Full = Template.bind({});
Full.args = {
  devices: [
    { id: `1`, icon: `laptop`, model: `13" MacBook Air`, status: `online` },
    { id: `2`, icon: `laptop`, model: `Mac Mini`, status: `offline` },
    { id: `3`, icon: `laptop`, model: `iMac`, status: `offline` },
  ],
  name: `John Doe`,
  numKeychains: 32,
  numKeys: 1546,
  screenshotsEnabled: true,
  keystrokesEnabled: true,
};
