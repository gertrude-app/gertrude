import { UserActivityOverview } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import { props, time } from '../../../story-helpers';

const meta = {
  title: 'Dashboard/Users/Activity/UserActivityOverview', // eslint-disable-line
  component: UserActivityOverview,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof UserActivityOverview>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Default: Story = props({
  userName: `Huck`,
  days: [
    {
      date: new Date(time.stable()),
      numItems: 330,
      index: 0,
      numDays: 3,
      numCompleted: 0,
    },
    {
      date: new Date(time.stable()),
      numItems: 117,
      index: 1,
      numDays: 3,
      numCompleted: 64,
    },
    {
      date: new Date(time.stable()),
      numItems: 89,
      index: 2,
      numDays: 3,
      numCompleted: 89,
    },
  ],
});

export const Single: Story = props({
  userName: `Huck`,
  days: [
    {
      date: new Date(time.stable()),
      numItems: 330,
      index: 0,
      numDays: 3,
      numCompleted: 330,
    },
  ],
});

export const Empty: Story = props({
  ...Default.args,
  days: [],
});

export default meta;
