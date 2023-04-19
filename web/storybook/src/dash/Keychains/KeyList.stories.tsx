import { KeyList } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { keyExamples, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Keychains/KeyList', // eslint-disable-line
  component: KeyList,
} satisfies Meta<typeof KeyList>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs/400,md/400
export const Default: Story = props({
  keys: Object.values(keyExamples),
});

export default meta;
