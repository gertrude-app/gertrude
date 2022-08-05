import { ComponentStory, ComponentMeta } from '@storybook/react';

import UserDevice from './UserDevice';

export default {
  title: 'UserDevice',
  component: UserDevice,
} as ComponentMeta<typeof UserDevice>;

const Template: ComponentStory<typeof UserDevice> = (args) => <UserDevice {...args} />;

export const Online = Template.bind({});
Online.args = { type: `14" Macbook Pro`, status: `online` };

export const Offline = Template.bind({});
Offline.args = { type: `14" Macbook Pro`, status: `offline` };
