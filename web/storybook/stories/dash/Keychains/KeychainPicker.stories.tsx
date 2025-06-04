import { KeychainPicker, Modal } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { keychainProps, keychains, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Keychains/KeychainPicker', // eslint-disable-line
  component: KeychainPicker,
  decorators: [
    (Story) => (
      <Modal
        type="container"
        title="Select a keychain"
        primaryButton={{ label: `Add keychain`, action: () => {} }}
        secondaryButton={() => {}}
      >
        <Story />
      </Modal>
    ),
  ],
} satisfies Meta<typeof KeychainPicker>;

type Story = StoryObj<typeof meta>;

const publicKeychains = [
  keychainProps({ name: `HTC`, numKeys: 232, isPublic: true }),
  keychainProps({ name: `Meyer Hatchery`, numKeys: 14, isPublic: true }),
  keychainProps({ name: `Gertrude.com`, numKeys: 1, isPublic: true }),
];

// @screenshot: xs/1300,lg/900
export const AddToUserHappyPath: Story = props({
  mode: `addToUser`,
  userName: `Little Jimmy`,
  userId: `1234`,
  hasNoOwnKeychains: false,
  selectableOwnKeychains: keychains.filter((kc) => !kc.isPublic),
  selectablePublicKeychains: publicKeychains,
  onSelect: () => {},
});

// @screenshot: xs/1000,lg
export const AddToUserNoOwnKeychains: Story = props({
  ...AddToUserHappyPath.args,
  hasNoOwnKeychains: true,
  selectableOwnKeychains: [],
});

// @screenshot: xs/1000,lg
export const AddToUserHasAllPersonalKeychains: Story = props({
  ...AddToUserHappyPath.args,
  hasNoOwnKeychains: false,
  selectableOwnKeychains: [],
  userName: `Little Jimmy`,
});

export const ForUnlockRequestHappyPath: Story = props({
  mode: `forUnlockRequestKey`,
  userName: `Little Jimmy`,
  userId: `1234`,
  hasNoOwnKeychains: false,
  selectableOwnKeychains: keychains.filter((kc) => !kc.isPublic),
  selectablePublicKeychains: publicKeychains,
  onSelect: () => {},
});

// @screenshot: xs
export const ForUnlockRequestNoPersonalKeychains: Story = props({
  ...ForUnlockRequestHappyPath.args,
  mode: `forUnlockRequestKey`,
  hasNoOwnKeychains: true,
  userName: `Little Jimmy`,
  selectableOwnKeychains: [],
});

// @screenshot: xs
export const ForUnlockRequestUserNeedsAKeychain: Story = props({
  ...ForUnlockRequestHappyPath.args,
  mode: `forUnlockRequestKey`,
  hasNoOwnKeychains: false,
  userName: `Little Jimmy`,
  selectableOwnKeychains: [],
});

export default meta;
