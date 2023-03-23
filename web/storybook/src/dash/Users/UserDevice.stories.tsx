import { UserDevice } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Users/UserDevice', // eslint-disable-line
  component: UserDevice,
} as ComponentMeta<typeof UserDevice>;

const Template: StoryFn<typeof UserDevice> = (args) => <UserDevice {...args} />;

export const Online = Template.bind({});
Online.args = { model: `14" Macbook Pro`, icon: `laptop`, status: `online` };

export const Offline = Template.bind({});
Offline.args = { ...Online.args, status: `offline` };
