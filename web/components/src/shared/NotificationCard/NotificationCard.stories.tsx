import { ComponentStory, ComponentMeta } from '@storybook/react';

import NotificationCard from './NotificationCard';

export default {
  title: 'NotificationCard',
  component: NotificationCard,
} as ComponentMeta<typeof NotificationCard>;

const Template: ComponentStory<typeof NotificationCard> = (args) => <NotificationCard {...args} />;

export const Default = Template.bind({});
