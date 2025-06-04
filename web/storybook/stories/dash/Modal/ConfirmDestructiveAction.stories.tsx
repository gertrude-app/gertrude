import { ConfirmDestructiveAction } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Modal/ConfirmDestructiveAction', // eslint-disable-line
  component: ConfirmDestructiveAction,
} satisfies Meta<typeof ConfirmDestructiveAction>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  openWhenPresent: `some-id`,
  onConfirm: () => {},
  onDismiss: () => {},
  title: `Delete your only widget?`,
  children: (
    <>
      Are you <b>sure?</b> There is no undo.
    </>
  ),
});

export default meta;
