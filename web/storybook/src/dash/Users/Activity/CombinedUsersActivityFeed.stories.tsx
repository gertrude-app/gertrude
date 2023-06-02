import { CombinedUsersActivityFeed } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import { activity, time } from '../../../story-helpers';

export default {
  title: 'Dashboard/Users/Activity/CombinedUsersActivityFeed', // eslint-disable-line
  component: CombinedUsersActivityFeed,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof CombinedUsersActivityFeed>;

const Template: ComponentStory<typeof CombinedUsersActivityFeed> = (args) => (
  <CombinedUsersActivityFeed {...args} />
);

// @screenshot: xs,md
export const Default = Template.bind({});
Default.args = {
  date: new Date(time.stable()),
  chunkSize: 3,
  activity,
  numDeleted: 0,
  deleteItems: () => {},
};

export const Empty = Template.bind({});
Empty.args = { ...Default.args, activity: [] };
