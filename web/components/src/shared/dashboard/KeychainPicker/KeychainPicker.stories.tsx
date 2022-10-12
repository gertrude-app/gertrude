import { ComponentStory, ComponentMeta } from '@storybook/react';
import Modal from '../Modal';
import { keychainProps, keychains } from '../story-helpers';
import KeychainPicker from './KeychainPicker';

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
    type={`container`}
    title={`Select a keychain`}
    isOpen={true}
    primaryButtonText="Add keychain"
    onPrimaryClick={() => {}}
    onDismiss={() => {}}
  >
    <KeychainPicker {...args} />
  </Modal>
);

export const Default = Template.bind({});
Default.args = {
  selectableOwnKeychains: keychains,
  selectablePublicKeychains: publicKeychains,
};

export const NoKeychains = Template.bind({});
NoKeychains.args = { ...Default.args, selectableOwnKeychains: [] };
