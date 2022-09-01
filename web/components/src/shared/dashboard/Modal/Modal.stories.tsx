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
  openWhenPresent: true,
  onDismiss: () => {},
  onConfirm: () => {},
};
