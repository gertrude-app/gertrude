import { EditKeychain } from '@dash/components';
import { newKeyState } from '@dash/keys';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { confirmableEntityAction } from '../../story-helpers';

export default {
  title: 'Dashboard/Keychains/Edit', // eslint-disable-line
  component: EditKeychain,
  screenshot: true,
} as ComponentMeta<typeof EditKeychain>;

const Template: ComponentStory<typeof EditKeychain> = (args) => (
  <EditKeychain {...args} />
);

// @screenshot: xs,md
export const Default = Template.bind({});
Default.args = {
  isNew: false,
  name: `HTC`,
  description: `A collection of keys for Jared's HTC class.`,
  keys: [],
  setName: () => {},
  onSave: () => {},
  setDescription: () => {},
  saveButtonDisabled: false,
  deleteKeychain: confirmableEntityAction<void>(),
  deleteKey: confirmableEntityAction(),
};

export const New = Template.bind({});
New.args = {
  ...Default.args,
  isNew: true,
};

// @screenshot: xs/900
export const CreatingKey = Template.bind({});
CreatingKey.args = {
  ...Default.args,
  editingKey: newKeyState(`keyid`, `keychainid`),
};
