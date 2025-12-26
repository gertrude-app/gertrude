import { UserActivityWidget } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props, withIdsAnd } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Dashboard/Widgets/ChildActivity', // eslint-disable-line
  component: UserActivityWidget,
} satisfies Meta<typeof UserActivityWidget>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  userActivity: withIdsAnd({ numReviewed: 0 }, [
    { name: `Little Jimmy`, numUnreviewed: 245 },
    { name: `Sally`, numUnreviewed: 0 },
    { name: `Henry`, numUnreviewed: 23 },
  ]),
});

// @screenshot: xs/250
export const AllCaughtUp: Story = props({
  userActivity: withIdsAnd({ numReviewed: 0 }, [
    { name: `Little Jimmy`, numUnreviewed: 0 },
    { name: `Sally`, numUnreviewed: 0 },
    { name: `Henry`, numUnreviewed: 0 },
  ]),
});

export const NoChildren: Story = props({
  userActivity: [],
});

export default meta;
