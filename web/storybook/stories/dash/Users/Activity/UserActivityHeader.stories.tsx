import { UserActivityHeader } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';

const meta = {
  title: 'Dashboard/Users/Activity/UserActivityHeader', // eslint-disable-line
  component: UserActivityHeader,
} satisfies Meta<typeof UserActivityHeader>;

type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: { children: `Little Jimmy` },
};

export default meta;
