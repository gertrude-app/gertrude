import { CombinedUsersActivityFeed } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import { activity, props, time } from '../../../story-helpers';

const meta: Meta = {
  title: 'Dashboard/Users/Activity/CombinedUsersActivityFeed', // eslint-disable-line
  component: CombinedUsersActivityFeed,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof CombinedUsersActivityFeed>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Default: Story = props({
  date: new Date(time.stable()),
  chunkSize: 3,
  activity,
  numDeleted: 0,
  deleteItems: () => {},
});

export const Empty: Story = props({
  ...Default.args,
  activity: [],
});

export default meta;
