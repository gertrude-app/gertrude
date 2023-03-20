import { Modal, SuspendFilterRequestForm } from '@dash/components';
import type { StoryFn, ComponentMeta, DecoratorFn } from '@storybook/react';

const inModal: DecoratorFn = (Story) => (
  <Modal
    type="container"
    title="Suspend Filter Request"
    icon="stopwatch"
    isOpen
    primaryButton={{ label: `Grant`, action: () => {} }}
    secondaryButton={{ label: `Deny`, action: () => {} }}
  >
    <Story />
  </Modal>
);

export default {
  title: 'Dashboard/Users/SuspendFilterRequestForm', // eslint-disable-line
  component: SuspendFilterRequestForm,
  decorators: [inModal],
} as ComponentMeta<typeof SuspendFilterRequestForm>;

const Template: StoryFn<typeof SuspendFilterRequestForm> = (args) => (
  <SuspendFilterRequestForm {...args} />
);

// @screenshot: xs,md
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

// @screenshot: xs,md
export const CustomDuration = Template.bind({});
CustomDuration.args = {
  ...Default.args,
  durationInSeconds: `custom`,
  customDurationInMinutes: `77`,
};
