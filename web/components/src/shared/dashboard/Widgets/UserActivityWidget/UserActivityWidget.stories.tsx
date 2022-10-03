import { ComponentStory, ComponentMeta } from '@storybook/react';
import UserActivityWidget from './UserActivityWidget';

export default {
  title: `UserActivityWidget`,
  component: UserActivityWidget,
} as ComponentMeta<typeof UserActivityWidget>;

const Template: ComponentStory<typeof UserActivityWidget> = (args) => <UserActivityWidget {...args} />;

export const Default = Template.bind({});
