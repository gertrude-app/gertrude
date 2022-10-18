import { ComponentStory, ComponentMeta, DecoratorFn } from '@storybook/react';
import Modal from '../../Modal';
import SuspendFilterRequestForm from './SuspendFilterRequestForm';

const inModal: DecoratorFn = (Story) => (
  <Modal
    type="default"
    title="Suspend Filter Request"
    icon="stopwatch"
    isOpen
    primaryButtonText="Grant"
    secondaryButtonText="Deny"
    onPrimaryClick={() => {}}
    onDismiss={() => {}}
  >
    <Story />
  </Modal>
);

export default {
  title: `SuspendFilterRequestForm`,
  component: SuspendFilterRequestForm,
  decorators: [inModal],
} as ComponentMeta<typeof SuspendFilterRequestForm>;

const Template: ComponentStory<typeof SuspendFilterRequestForm> = (args) => (
  <SuspendFilterRequestForm {...args} />
);

export const Default = Template.bind({});
Default.args = {
  username: `Win`,
  timeRequested: `2021-03-01 12:00:00`,
  requestComment: `Watch some videos for Al's class`,
  requestedDurationInSeconds: 60 * 5,
  durationInSeconds: `60`,
  customDurationInMinutes: ``,
  responseComment: ``,
  setResponseComment: () => {},
  setDuration: () => {},
  setCustomDuration: () => {},
};

export const CustomDuration = Template.bind({});
CustomDuration.args = {
  ...Default.args,
  durationInSeconds: `custom`,
  customDurationInMinutes: `77`,
};
