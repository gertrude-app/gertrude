import { ConfirmDeleteEntity } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Modal/ConfirmDeleteEntity', // eslint-disable-line
  component: ConfirmDeleteEntity,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof ConfirmDeleteEntity>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  type: `widget`,
  action: {
    id: `some-id`,
    start: () => {},
    confirm: () => {},
    cancel: () => {},
  },
});

export default meta;
