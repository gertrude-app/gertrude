import { ComponentStory, ComponentMeta, DecoratorFn } from '@storybook/react';
import { Modal, UnlockRequestResponder } from '@dash/components';
import { time } from '../../story-helpers';

const inModal: DecoratorFn = (Story) => (
  <Modal
    type="container"
    title="Unlock Request"
    icon="unlock"
    isOpen
    primaryButtonText="Accept"
    secondaryButtonText="Deny"
    onPrimaryClick={() => {}}
    onSecondaryClick={() => {}}
  >
    <Story />
  </Modal>
);

export default {
  title: `Dashboard/Users/UnlockRequestResponder`,
  component: UnlockRequestResponder,
  decorators: [inModal],
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof UnlockRequestResponder>;

const Template: ComponentStory<typeof UnlockRequestResponder> = (args) => (
  <UnlockRequestResponder {...args} />
);

export const FirstStep = Template.bind({});
FirstStep.args = {
  step: `reviewing`,
  userName: `Winfield`,
  requestComment: `schedule mayra appointments`,
  url: `https://cdn-s.acuityscheduling.com/logo24613730.jpg?1650316493&whiteBg=1&rectangular=1`,
  domain: `cdn-s.acuityscheduling.com`,
  ipAddress: `151.101.2.132`,
  createdAt: time.subtracting({ minutes: 36 }),
  appName: `Safari Browser`,
  appCategories: [`browser`],
  appBundleId: `.com.apple.Safari`,
  requestProtocol: `TCP`,
};

export const NoAppName = Template.bind({});
NoAppName.args = {
  ...FirstStep.args,
  appName: undefined,
};

export const EmptyStringComment = Template.bind({});
EmptyStringComment.args = {
  ...FirstStep.args,
  requestComment: ``,
};

export const SecondStep = Template.bind({});
SecondStep.args = {
  ...FirstStep.args,
  step: `editingKey`,
};

export const ThirdStep = Template.bind({});
ThirdStep.args = {
  ...FirstStep.args,
  step: `selectingKeychain`,
};
