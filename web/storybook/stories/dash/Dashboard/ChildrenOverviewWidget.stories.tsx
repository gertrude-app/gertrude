import { UsersOverviewWidget } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props, withIds } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Dashboard/Widgets/ChildrenOverview', // eslint-disable-line
  component: UsersOverviewWidget,
} satisfies Meta<typeof UsersOverviewWidget>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  users: withIds([
    {
      name: `Little Jimmy`,
      devices: [
        {
          platform: `mac`,
          deviceName: `MacBook Pro`,
          macStatus: {
            case: `filterSuspended`,
            resuming: new Date(new Date().getTime() + 7 * 60 * 1000).toISOString(),
          },
        },
      ],
    },
    {
      name: `Sally`,
      devices: [
        {
          platform: `mac`,
          deviceName: `iMac`,
          macStatus: {
            case: `downtime`,
            ending: new Date(new Date().getTime() + 60 * 60 * 1000).toISOString(),
          },
        },
        { platform: `mac`, deviceName: `MacBook Air`, macStatus: { case: `offline` } },
      ],
    },
    {
      name: `Henry`,
      devices: [
        {
          platform: `mac`,
          deviceName: `Mac Mini`,
          macStatus: {
            case: `downtimePaused`,
            resuming: new Date(new Date().getTime() + 5 * 60 * 1000).toISOString(),
          },
        },
        { platform: `mac`, deviceName: `MacBook Pro`, macStatus: { case: `filterOn` } },
        { platform: `ios`, deviceName: `iPhone 14`, iosStatus: `setupComplete` },
      ],
    },
    {
      name: `Humphry`,
      devices: [
        { platform: `mac`, deviceName: `MacBook Air`, macStatus: { case: `offline` } },
      ],
    },
    {
      name: `Hon`,
      devices: [
        { platform: `mac`, deviceName: `iMac`, macStatus: { case: `filterOff` } },
      ],
    },
    {
      name: `Hilda`,
      devices: [
        { platform: `mac`, deviceName: `Mac Mini`, macStatus: { case: `filterOn` } },
      ],
    },
  ]),
});

export const NoChildren: Story = props({
  users: [],
});

export default meta;
