import { Modal, SuspendFilterRequestForm } from '@dash/components';
import type { ComponentStory, ComponentMeta, DecoratorFn } from '@storybook/react';

const inModal: DecoratorFn = (Story) => (
  <Modal
    type="container"
    title="Suspend Filter Request"
    icon="stopwatch"
    isOpen
    primaryButtonText="Grant"
    secondaryButtonText="Deny"
    onPrimaryClick={() => {}}
    onSecondaryClick={() => {}}
  >
    <Story />
  </Modal>
);

export default {
  title: `Dashboard/Users/SuspendFilterRequestForm`,
  component: SuspendFilterRequestForm,
  decorators: [inModal],
} as ComponentMeta<typeof SuspendFilterRequestForm>;

const Template: ComponentStory<typeof SuspendFilterRequestForm> = (args) => (
  <SuspendFilterRequestForm {...args} />
);

export const Default = Template.bind({});
Default.args = {
  username: `Win`,
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
