import { Modal, KeychainPicker } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
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

const Template: ComponentStory<typeof KeychainPicker> = (args) => (
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
export const Default = Template.bind({});
Default.args = {
  mode: `addToUser`,
  selectableOwnKeychains: keychains.filter((kc) => !kc.isPublic),
  selectablePublicKeychains: publicKeychains,
};

// @screenshot: xs/1000,lg
export const NoOwnKeychains = Template.bind({});
NoOwnKeychains.args = {
  ...Default.args,
  hasNoOwnKeychains: true,
  selectableOwnKeychains: [],
};

export const AllOwnKeychainsAttached = Template.bind({});
AllOwnKeychainsAttached.args = {
  ...Default.args,
  hasNoOwnKeychains: false,
  selectableOwnKeychains: [],
};

// @screenshot: xs
export const NoKeychainsForUnlockRequest = Template.bind({});
NoKeychainsForUnlockRequest.args = {
  ...Default.args,
  mode: `forUnlockRequestKey`,
  hasNoOwnKeychains: true,
  selectableOwnKeychains: [],
};
