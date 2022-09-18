import { ComponentStory, ComponentMeta } from '@storybook/react';
import { SubcomponentsOmit } from '../../types';
import Modal from '../Modal';
import { keychainProps } from '../story-helpers';
import KeychainCard from '../Users/KeychainCard';
import KeychainPicker from './KeychainPicker';

export default {
  title: `Dashboard/Keychains/KeychainPicker`,
  component: KeychainPicker,
} as ComponentMeta<typeof KeychainPicker>;

const keychains: SubcomponentsOmit<typeof KeychainCard, 'onRemove'> = [
  keychainProps({ id: `id-htc`, name: `HTC`, keys: 232, isPublic: true }),
  keychainProps({ name: `Jimmy's Music Theory`, keys: 7 }),
  keychainProps({ name: `Jason's blog`, keys: 3, description: undefined }),
  keychainProps({ name: `Misc McStrandardishlong Keys`, keys: 1027 }),
  keychainProps({ name: `John's stuff`, keys: 674 }),
  keychainProps({ name: `Smith family`, keys: 9, description: `A short description` }),
  keychainProps({ name: `Meyer Hatchery`, keys: 14, isPublic: true }),
  keychainProps({ name: `Facebook`, keys: 2390 }),
  keychainProps({
    name: `Friends Library Internationalization Remote Safety Keychain for MSF`,
    keys: 2,
    description: `Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.`,
  }),
];

const publicKeychains: SubcomponentsOmit<typeof KeychainCard, 'onRemove'> = [
  keychainProps({ id: `id-htc`, name: `HTC`, keys: 232, isPublic: true }),
  keychainProps({ name: `Meyer Hatchery`, keys: 14, isPublic: true }),
  keychainProps({ name: `Google`, keys: 1402, isPublic: true }),
  keychainProps({ name: `Gertrude.com`, keys: 1, isPublic: true }),
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
Default.args = { keychains, publicKeychains };

export const NoKeychains = Template.bind({});
NoKeychains.args = { keychains: [], publicKeychains };
