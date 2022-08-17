import { ComponentStory, ComponentMeta } from '@storybook/react';

import NewNotificationMethodSidebar from './NewNotificationMethodSidebar';

export default {
  title: `Dashboard/Profile/NewNotificationMethodSidebar`,
  component: NewNotificationMethodSidebar,
} as ComponentMeta<typeof NewNotificationMethodSidebar>;

const Template: ComponentStory<typeof NewNotificationMethodSidebar> = (args) => (
  <NewNotificationMethodSidebar {...args} />
);

export const Default = Template.bind({});
Default.args = { open: true };
