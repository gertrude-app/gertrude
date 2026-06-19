import { EditChild } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { confirmableEntityAction, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Children/EditChild', // eslint-disable-line
  component: EditChild,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof EditChild>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Default: Story = props({
  id: `1`,
  isNew: false,
  name: `Little Jimmy`,
  setName: () => {},
  saveButtonDisabled: true,
  onSave: () => {},
  startAddDevice: () => {},
  dismissAddDevice: () => {},
  startAddIOSDevice: () => {},
  dismissAddIOSDevice: () => {},
  onStartTrial: () => {},
  deleteUser: confirmableEntityAction(),
  deleteDevice: confirmableEntityAction(),
  computers: [
    {
      id: `1`,
      computerId: `1`,
      customName: `Silvery`,
      modelIdentifier: `Mac14,10`,
      modelTitle: `16" MacBook Pro (2023)`,
      modelFamily: `macBookPro`,
      status: {
        case: `filterSuspended`,
        resuming: new Date(new Date().getTime() + 1000 * 60 * 12).toISOString(),
      },
    },
    {
      id: `2`,
      computerId: `2`,
      modelIdentifier: `Mac14,14`,
      modelTitle: `Mac Studio (2023)`,
      modelFamily: `studio`,
      status: { case: `offline` },
    },
  ],
  iosDevices: [
    {
      id: `3`,
      modelName: `iPhone 14`,
      deviceType: `iPhone`,
      iosVersion: `iOS 18.2`,
      pendingClaimCode: 123456,
      musicConnected: false,
    },
  ],
});

// @screenshot: xs,md
export const New: Story = props({
  ...Default.args,
  name: ``,
  isNew: true,
});

// @screenshot: xs,md
export const NoDevices: Story = props({
  ...Default.args,
  computers: [],
  iosDevices: [],
});

export default meta;
