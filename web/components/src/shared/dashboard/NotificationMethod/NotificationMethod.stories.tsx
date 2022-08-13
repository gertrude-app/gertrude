import { ComponentStory, ComponentMeta } from '@storybook/react';

import NotificationMethod from './NotificationMethod';

export default {
  title: `NotificationMethod`,
  component: NotificationMethod,
} as ComponentMeta<typeof NotificationMethod>;

const Template: ComponentStory<typeof NotificationMethod> = (args) => (
  <NotificationMethod {...args} />
);

export const Default = Template.bind({});
