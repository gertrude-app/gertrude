import { EditUser } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { confirmableEntityAction, props, keychainProps } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Users/EditUser', // eslint-disable-line
  component: EditUser,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof EditUser>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Default: Story = props({
  id: `1`,
  isNew: false,
  name: `Little Jimmy`,
  setName: () => {},
  keyloggingEnabled: false,
  setKeyloggingEnabled: () => {},
  screenshotsEnabled: false,
  setScreenshotsEnabled: () => {},
  screenshotsFrequency: 120,
  setScreenshotsFrequency: () => {},
  screenshotsResolution: 1000,
  setScreenshotsResolution: () => {},
  saveButtonDisabled: true,
  onSave: () => {},
  onConfirmAddKeychain: () => {},
  onDismissAddKeychain: () => {},
  onAddKeychainClicked: () => {},
  startAddDevice: () => {},
  dismissAddDevice: () => {},
  deleteUser: confirmableEntityAction(),
  deleteDevice: confirmableEntityAction(),
  keychains: [
    keychainProps({ name: `HTC`, numKeys: 43, isPublic: true }),
    keychainProps({ name: `Public Speaking`, numKeys: 7, isPublic: false }),
  ],
  devices: [
    { id: `1`, model: `M1 MacbookAir (2021)`, status: `online`, icon: `laptop` },
    { id: `2`, model: `Mac Mini (2018)`, status: `offline`, icon: `desktop` },
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
  devices: [],
});

export default meta;
