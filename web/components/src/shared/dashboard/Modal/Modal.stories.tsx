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
  type: `default`,
  title: `Just fyi...`,
  isOpen: true,
  onPrimaryClick: () => {},
  onDismiss: () => {},
  children: (
    <>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Dolorem aliquam autem eius,
      facere laudantium temporibus ea quasi.
    </>
  ),
  icon: 'info',
};

export const Destructive = Template.bind({});
Destructive.args = {
  type: `destructive`,
  title: `NOOOOOOOOO!!!`,
  isOpen: true,
  onPrimaryClick: () => {},
  onDismiss: () => {},
  children: (
    <>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Dolorem aliquam autem eius,
      facere laudantium temporibus ea quasi.
    </>
  ),
  icon: 'exclamation-triangle',
};
