import { ComponentStory, ComponentMeta } from '@storybook/react';
import UserActivityReviewDayScreen from './UserActivityReviewDayScreen';

export default {
  title: `Dashboard/UserActivity/ReviewDayScreen`,
  component: UserActivityReviewDayScreen,
} as ComponentMeta<typeof UserActivityReviewDayScreen>;

const Template: ComponentStory<typeof UserActivityReviewDayScreen> = (args) => (
  <UserActivityReviewDayScreen {...args} />
);

export const Default = Template.bind({});
