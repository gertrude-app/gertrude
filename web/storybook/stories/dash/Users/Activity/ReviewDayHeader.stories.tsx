import { FeedHeader } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props, time } from '../../../story-helpers';

const meta: Meta = {
  title: 'Dashboard/Users/Activity/FeedHeader', // eslint-disable-line
  component: FeedHeader,
} satisfies Meta<typeof FeedHeader>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  date: new Date(time.stable()),
  numItems: 63,
  numDeleted: 0,
});

export const Empty = props({
  ...Default.args,
  numItems: 0,
  numDeleted: 0,
});

export const Completed = props({
  ...Default.args,
  numItems: 6,
  numDeleted: 6,
});

export default meta;
