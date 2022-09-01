import { ComponentStory, ComponentMeta } from '@storybook/react';
import Modal from './Modal';

export default {
  title: `Dashboard/Core/Modal`,
  component: Modal,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof Modal>;

const Template: ComponentStory<typeof Modal> = (args) => <Modal {...args} />;

export const Default = Template.bind({});
Default.args = {
  type: `destructive`,
  title: `Do you want to delete this widget?`,
  isOpen: true,
  onPrimaryClick: () => {},
  onDismiss: () => {},
  children: (
    <>
      Are you <b>sure?</b> There is no undo, and you might regret your decision in the
      morning.
    </>
  ),
};
