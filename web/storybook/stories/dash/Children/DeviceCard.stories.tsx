import { DeviceCard } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Children/DeviceCard',
  component: DeviceCard,
} satisfies Meta<typeof DeviceCard>;

type Story = StoryObj<typeof meta>;

export const Online: Story = props({
  to: `/devices/d1`,
  imageSrc: `/macs/Mac14,10.png`,
  imageAlt: `15" Macbook Pro (2023)`,
  title: `Silvery`,
  subtitle: `15" Macbook Pro (2023)`,
  status: { case: `computerStatus`, status: { case: `filterOn` } },
});

export const Offline: Story = props({
  ...Online.args,
  status: { case: `computerStatus`, status: { case: `offline` } },
});

export const Suspended: Story = props({
  ...Online.args,
  status: {
    case: `computerStatus`,
    status: {
      case: `filterSuspended`,
      resuming: new Date(new Date().getTime() + 7 * 60 * 1000).toISOString(),
    },
  },
});

export const Downtime: Story = props({
  ...Online.args,
  status: {
    case: `computerStatus`,
    status: {
      case: `downtime`,
      ending: new Date(new Date().getTime() + 60 * 60 * 1000).toISOString(),
    },
  },
});

export const DowntimePaused: Story = props({
  ...Online.args,
  status: {
    case: `computerStatus`,
    status: {
      case: `downtimePaused`,
      resuming: new Date(new Date().getTime() + 5 * 60 * 1000).toISOString(),
    },
  },
});

export const FilterOff: Story = props({
  ...Online.args,
  status: { case: `computerStatus`, status: { case: `filterOff` } },
});

export const NoSubtitle: Story = props({
  ...Online.args,
  title: `15" Macbook Pro (2023)`,
  subtitle: undefined,
});

export const PendingIosDevice: Story = props({
  to: `/supervise-device/847293/download-helper`,
  imageSrc: `/ios/iPhone.png`,
  imageAlt: `iPhone 14`,
  title: `iPhone 14`,
  subtitle: `iOS 17.6`,
  status: { case: `pendingSetup` },
});

export default meta;
