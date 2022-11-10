import { Modal, KeychainPicker } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { keychainProps, keychains } from '../../story-helpers';

export default {
  title: `Dashboard/Keychains/KeychainPicker`,
  component: KeychainPicker,
} as ComponentMeta<typeof KeychainPicker>;

const publicKeychains = [
  keychainProps({ id: `id-htc`, name: `HTC`, numKeys: 232, isPublic: true }),
  keychainProps({ name: `Meyer Hatchery`, numKeys: 14, isPublic: true }),
  keychainProps({ name: `Google`, numKeys: 1402, isPublic: true }),
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

export const Default = Template.bind({});
Default.args = {
  mode: `addToUser`,
  selectableOwnKeychains: keychains,
  selectablePublicKeychains: publicKeychains,
};

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

export const NoKeychainsForUnlockRequest = Template.bind({});
NoKeychainsForUnlockRequest.args = {
  ...Default.args,
  mode: `forUnlockRequestKey`,
  hasNoOwnKeychains: true,
  selectableOwnKeychains: [],
};
