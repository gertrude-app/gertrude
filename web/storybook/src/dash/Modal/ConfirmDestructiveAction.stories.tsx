import { ConfirmDestructiveAction } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Modal/ConfirmDestructiveAction', // eslint-disable-line
  component: ConfirmDestructiveAction,
} as ComponentMeta<typeof ConfirmDestructiveAction>;

const Template: StoryFn<typeof ConfirmDestructiveAction> = (args) => (
  <ConfirmDestructiveAction {...args} />
);

export const Default = Template.bind({});
Default.args = {
  openWhenPresent: `some-id`,
  onConfirm: () => {},
  onDismiss: () => {},
  title: `Delete your only widget?`,
  children: (
    <>
      Are you <b>sure?</b> There is no undo.
    </>
  ),
};
