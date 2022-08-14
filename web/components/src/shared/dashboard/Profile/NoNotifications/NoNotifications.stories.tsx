import { ComponentStory, ComponentMeta } from '@storybook/react';

import NoNotifications from './NoNotifications';

export default {
  title: `Dashboard/Profile/NoNotifications`,
  component: NoNotifications,
} as ComponentMeta<typeof NoNotifications>;

const Template: ComponentStory<typeof NoNotifications> = (args) => (
  <NoNotifications {...args} />
);

export const Default = Template.bind({});
