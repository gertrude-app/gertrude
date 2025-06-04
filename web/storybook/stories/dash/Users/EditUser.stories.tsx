import { EditUser } from '@dash/components';
import { defaults } from '@dash/types';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { confirmableEntityAction, props, userKeychainProps } from '../../story-helpers';

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
  keyloggingEnabled: true,
  screenshotsEnabled: true,
  setName: () => {},
  setKeyloggingEnabled: () => {},
  removeKeychain: () => {},
  onSelectKeychainToAdd: () => {},
  setScreenshotsEnabled: () => {},
  screenshotsFrequency: 120,
  setScreenshotsFrequency: () => {},
  screenshotsResolution: 1000,
  setScreenshotsResolution: () => {},
  showSuspensionActivity: true,
  setShowSuspensionActivity: () => {},
  saveButtonDisabled: true,
  onSave: () => {},
  onConfirmAddKeychain: () => {},
  onDismissAddKeychain: () => {},
  onAddKeychainClicked: () => {},
  startAddDevice: () => {},
  dismissAddDevice: () => {},
  deleteUser: confirmableEntityAction(),
  deleteDevice: confirmableEntityAction(),
  downtimeEnabled: false,
  downtime: { start: { hour: 0, minute: 0 }, end: { hour: 1, minute: 0 } },
  setDowntimeEnabled: () => {},
  setDowntime: () => {},
  updateNewBlockedAppIdentifier: () => {},
  addNewBlockedApp: () => {},
  removeBlockedApp: () => {},
  newBlockedAppIdentifier: ``,
  setBlockedAppSchedule: () => {},
  blockedApps: [
    { id: `1`, identifier: `Notepad++` },
    {
      id: `2`,
      identifier: `Xcode`,
      schedule: defaults.ruleSchedule(),
    },
    {
      id: `3`,
      identifier: `Really really long app name`,
      schedule: {
        mode: `active`,
        days: {
          sunday: true,
          monday: true,
          tuesday: true,
          wednesday: true,
          thursday: true,
          friday: false,
          saturday: true,
        },
        window: {
          start: {
            hour: 6,
            minute: 0,
          },
          end: {
            hour: 17,
            minute: 30,
          },
        },
      },
    },
  ],
  setAssignedKeychainSchedule: () => {},
  setAddingKeychainSchedule: () => {},
  keychains: [
    userKeychainProps({ name: `HTC`, numKeys: 43, isPublic: true }),
    userKeychainProps({
      name: `Public Speaking`,
      numKeys: 7,
      isPublic: false,
      schedule: defaults.ruleSchedule(),
    }),
  ],
  devices: [
    {
      id: `1`,
      deviceId: `1`,
      name: `Silvery`,
      modelIdentifier: `Mac14,10`,
      modelTitle: `16" MacBook Pro (2023)`,
      status: {
        case: `filterSuspended`,
        resuming: new Date(new Date().getTime() + 1000 * 60 * 12).toISOString(),
      },
    },
    {
      id: `2`,
      deviceId: `2`,
      modelIdentifier: `Mac14,14`,
      modelTitle: `Mac Studio (2023)`,
      status: { case: `offline` },
    },
  ],
  requestPublicKeychainRequest: { state: `idle` },
  onRequestPublicKeychain: () => {},
});

// @screenshot: xs,md
export const EmptyStates: Story = props({
  ...Default.args,
  keychains: [],
  blockedApps: [],
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
