import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../../decorators/StatefulChrome';
import KeychainCard from '../../Users/KeychainCard';
import ListKeychains from './ListKeychains';

export default {
  title: `Dashboard/Keychains/ListKeychains`,
  component: ListKeychains,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof ListKeychains>;

const Template: ComponentStory<typeof ListKeychains> = (args) => (
  <ListKeychains {...args} />
);

export const Default = Template.bind({});
Default.args = {
  keychains: [
    keychainProps({ name: `HTC`, keys: 232, isPublic: true }),
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
  ],
};

export function keychainProps(
  override: Partial<React.ComponentProps<typeof KeychainCard>> = {},
): React.ComponentProps<typeof KeychainCard> & { id: UUID } {
  return {
    id: `id-${Math.random()}`,
    isPublic: false,
    name: `HTC`,
    description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
    keys: 232,
    onRemove: () => {},
    ...override,
  };
}
