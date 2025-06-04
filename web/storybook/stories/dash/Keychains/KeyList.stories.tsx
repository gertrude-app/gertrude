import { KeyList } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { keyExamples, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Keychains/KeyList', // eslint-disable-line
  component: KeyList,
} satisfies Meta<typeof KeyList>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs/400,md/400
export const List: Story = props({
  editKey: () => {},
  deleteKey: () => {},
  keys: Object.values(keyExamples),
  viewMode: `list`,
});

// @screenshot: lg/400,xl/400
export const Table: Story = props({
  ...List.args,
  keys: Object.values(keyExamples),
  viewMode: `table`,
});

export default meta;
