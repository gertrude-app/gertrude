import { EditKeychain } from '@dash/components';
import { newKeyState } from '@dash/keys';
import type { StoryObj, Meta } from '@storybook/react';
import { confirmableEntityAction, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Keychains/Edit', // eslint-disable-line
  component: EditKeychain,
} satisfies Meta<typeof EditKeychain>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Default: Story = props({
  isNew: false,
  name: `HTC`,
  description: `A collection of keys for Jared's HTC class.`,
  keys: [],
  setName: () => {},
  onSave: () => {},
  setDescription: () => {},
  beginEditKey: () => {},
  updateEditingKey: () => {},
  dismissEditKeyModal: () => {},
  onKeySave: () => {},
  onCreateNewKey: () => {},
  keyModalSaveButtonDisabled: false,
  saveButtonDisabled: false,
  deleteKeychain: confirmableEntityAction<void>(),
  deleteKey: confirmableEntityAction(),
  apps: [],
});

export const New: Story = props({
  ...Default.args,
  isNew: true,
});

// @screenshot: xs/900
export const CreatingKey: Story = props({
  ...Default.args,
  editingKey: newKeyState(`keyid`, `keychainid`),
});

export default meta;
