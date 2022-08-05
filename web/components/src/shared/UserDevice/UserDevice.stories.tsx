import { ComponentStory, ComponentMeta } from '@storybook/react';

import UserDevice from './UserDevice';

export default {
  title: 'UserDevice',
  component: UserDevice,
} as ComponentMeta<typeof UserDevice>;

const Template: ComponentStory<typeof UserDevice> = (args) => <UserDevice {...args} />;

export const Default = Template.bind({});
