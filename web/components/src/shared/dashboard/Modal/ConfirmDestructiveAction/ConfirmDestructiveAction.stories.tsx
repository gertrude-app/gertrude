import { ComponentStory, ComponentMeta } from '@storybook/react';
import ConfirmDestructiveAction from './ConfirmDestructiveAction';

export default {
  title: `Dashboard/Core/Modal/ConfirmDestructiveAction`,
  component: ConfirmDestructiveAction,
} as ComponentMeta<typeof ConfirmDestructiveAction>;

const Template: ComponentStory<typeof ConfirmDestructiveAction> = (args) => (
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
