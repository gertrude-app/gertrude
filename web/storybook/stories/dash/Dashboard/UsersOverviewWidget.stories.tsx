import { UsersOverviewWidget } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { withIds, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Dashboard/Widgets/UserOverview', // eslint-disable-line
  component: UsersOverviewWidget,
} satisfies Meta<typeof UsersOverviewWidget>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  users: withIds([
    {
      name: `Little Jimmy`,
      status: {
        case: `filterSuspended`,
        resuming: new Date(new Date().getTime() + 7 * 60 * 1000).toISOString(),
      },
      numDevices: 1,
    },
    {
      name: `Sally`,
      status: {
        case: `downtime`,
        ending: new Date(new Date().getTime() + 60 * 60 * 1000).toISOString(),
      },
      numDevices: 2,
    },
    {
      name: `Henry`,
      status: {
        case: `downtimePaused`,
        resuming: new Date(new Date().getTime() + 5 * 60 * 1000).toISOString(),
      },
      numDevices: 3,
    },
    { name: `Humphry`, status: { case: `offline` }, numDevices: 4 },
    { name: `Hon`, status: { case: `filterOff` }, numDevices: 5 },
    { name: `Hilda`, status: { case: `filterOn` }, numDevices: 5 },
  ]),
});

export const NoUsers: Story = props({
  users: [],
});

export default meta;
