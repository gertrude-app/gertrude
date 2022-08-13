import { ComponentStory, ComponentMeta } from '@storybook/react';

import NotificationMethodsMenu from './NotificationMethodsMenu';

export default {
  title: `NotificationMethodsMenu`,
  component: NotificationMethodsMenu,
} as ComponentMeta<typeof NotificationMethodsMenu>;

const Template: ComponentStory<typeof NotificationMethodsMenu> = (args) => (
  <NotificationMethodsMenu {...args} />
);

export const Default = Template.bind({});
