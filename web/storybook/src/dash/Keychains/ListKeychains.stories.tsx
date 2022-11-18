import { ListKeychains } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { keychainProps, withIdsAnd } from '../../story-helpers';
import { withStatefulChrome } from '../../decorators/StatefulChrome';

export default {
  title: 'Dashboard/Keychains/ListKeychains', // eslint-disable-line
  component: ListKeychains,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof ListKeychains>;

const Template: ComponentStory<typeof ListKeychains> = (args) => (
  <ListKeychains {...args} />
);

// @screenshot: md
export const Default = Template.bind({});
Default.args = {
  keychains: withIdsAnd({ mode: `list`, removeText: `Delete` } as const, [
    keychainProps({ name: `HTC`, numKeys: 232, isPublic: true }),
    keychainProps({ name: `Jimmy's Music Theory`, numKeys: 7 }),
    keychainProps({ name: `Jason's blog`, numKeys: 3, description: undefined }),
    keychainProps({ name: `Misc McStrandardishlong Keys`, numKeys: 1027 }),
    keychainProps({ name: `John's stuff`, numKeys: 674 }),
    keychainProps({
      name: `Smith family`,
      numKeys: 9,
      description: `A short description`,
    }),
    keychainProps({ name: `Meyer Hatchery`, numKeys: 14, isPublic: true }),
    keychainProps({ name: `Facebook`, numKeys: 2390 }),
    keychainProps({
      name: `Friends Library Internationalization Remote Safety Keychain for MSF`,
      numKeys: 2,
      description: `Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.`,
    }),
  ]),
  remove: {
    start: () => {},
    confirm: () => {},
    cancel: () => {},
  },
};

// @screenshot: md
export const Deleting = Template.bind({});
Deleting.args = {
  ...Default.args,
  keychains: Default.args.keychains!.slice(0, 1),
  remove: {
    ...Default.args.remove!,
    id: `id-htc`,
  },
};
