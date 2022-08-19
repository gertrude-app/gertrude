import { ComponentStory, ComponentMeta } from '@storybook/react';

import UserDevice from './UserDevice';

export default {
  title: `Dashboard/Users/List/Card/Device`,
  component: UserDevice,
} as ComponentMeta<typeof UserDevice>;

const Template: ComponentStory<typeof UserDevice> = (args) => <UserDevice {...args} />;

export const Online = Template.bind({});
Online.args = { model: `14" Macbook Pro`, icon: `laptop`, status: `online` };

export const Offline = Template.bind({});
Offline.args = { ...Online.args, status: `offline` };
