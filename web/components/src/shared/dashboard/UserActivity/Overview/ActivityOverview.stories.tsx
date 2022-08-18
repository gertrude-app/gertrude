import { ComponentStory, ComponentMeta } from '@storybook/react';

import ActivityOverview from './ActivityOverview';

export default {
  title: `Dashboard/UserActivity/ActivityOverview`,
  component: ActivityOverview,
} as ComponentMeta<typeof ActivityOverview>;

const Template: ComponentStory<typeof ActivityOverview> = (args) => (
  <ActivityOverview {...args} />
);

export const Default = Template.bind({});
