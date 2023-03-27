import { Modal, KeychainPicker } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';
import { keychainProps, keychains } from '../../story-helpers';

export default {
  title: 'Dashboard/Keychains/KeychainPicker', // eslint-disable-line
  component: KeychainPicker,
} as ComponentMeta<typeof KeychainPicker>;

const publicKeychains = [
  keychainProps({ name: `HTC`, numKeys: 232, isPublic: true }),
  keychainProps({ name: `Meyer Hatchery`, numKeys: 14, isPublic: true }),
  keychainProps({ name: `Gertrude.com`, numKeys: 1, isPublic: true }),
];

const Template: StoryFn<typeof KeychainPicker> = (args) => (
  <Modal
    type="container"
    title="Select a keychain"
    primaryButton={{ label: `Add keychain`, action: () => {} }}
    secondaryButton={() => {}}
  >
    <KeychainPicker {...args} />
  </Modal>
);

// @screenshot: xs/1300,lg/900
export const AddToUserHappyPath = Template.bind({});
AddToUserHappyPath.args = {
  mode: `addToUser`,
  selectableOwnKeychains: keychains.filter((kc) => !kc.isPublic),
  selectablePublicKeychains: publicKeychains,
};

// @screenshot: xs/1000,lg
export const AddToUserNoOwnKeychains = Template.bind({});
AddToUserNoOwnKeychains.args = {
  ...AddToUserHappyPath.args,
  hasNoOwnKeychains: true,
  selectableOwnKeychains: [],
};

// @screenshot: xs/1000,lg
export const AddToUserHasAllPersonalKeychains = Template.bind({});
AddToUserHasAllPersonalKeychains.args = {
  ...AddToUserHappyPath.args,
  hasNoOwnKeychains: false,
  selectableOwnKeychains: [],
  userName: `Little Jimmy`,
};

export const ForUnlockRequestHappyPath = Template.bind({});
ForUnlockRequestHappyPath.args = {
  mode: `forUnlockRequestKey`,
  hasNoOwnKeychains: false,
  selectableOwnKeychains: keychains.filter((kc) => !kc.isPublic),
};

// @screenshot: xs
export const ForUnlockRequestNoPersonalKeychains = Template.bind({});
ForUnlockRequestNoPersonalKeychains.args = {
  ...ForUnlockRequestHappyPath.args,
  mode: `forUnlockRequestKey`,
  hasNoOwnKeychains: true,
  userName: `Little Jimmy`,
  selectableOwnKeychains: [],
};

// @screenshot: xs
export const ForUnlockRequestUserNeedsAKeychain = Template.bind({});
ForUnlockRequestUserNeedsAKeychain.args = {
  ...ForUnlockRequestHappyPath.args,
  mode: `forUnlockRequestKey`,
  hasNoOwnKeychains: false,
  userName: `Little Jimmy`,
  selectableOwnKeychains: [],
};
