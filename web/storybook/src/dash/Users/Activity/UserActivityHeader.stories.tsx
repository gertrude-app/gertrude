import { UserActivityHeader } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Users/Activity/UserActivityHeader', // eslint-disable-line
  component: UserActivityHeader,
} as ComponentMeta<typeof UserActivityHeader>;

const Template: ComponentStory<typeof UserActivityHeader> = (args) => (
  <UserActivityHeader {...args} />
);

export const Default = Template.bind({});
Default.args = {
  children: `Little Jimmy`,
};
