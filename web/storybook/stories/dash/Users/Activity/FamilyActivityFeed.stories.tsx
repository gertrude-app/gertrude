import { FamilyActivityFeed } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import { activity, props, time } from '../../../story-helpers';

const meta: Meta = {
  title: 'Dashboard/Users/Activity/FamilyActivityFeed', // eslint-disable-line
  component: FamilyActivityFeed,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof FamilyActivityFeed>;

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
