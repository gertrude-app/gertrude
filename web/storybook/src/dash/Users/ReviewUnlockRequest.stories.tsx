import { Modal, ReviewUnlockRequest } from '@dash/components';
import type { StoryFn, ComponentMeta, DecoratorFn } from '@storybook/react';
import { time } from '../../story-helpers';

const inModal: DecoratorFn = (Story) => (
  <Modal
    type="container"
    title="Unlock Request"
    icon="unlock"
    primaryButton={{ label: `Accept`, action: () => {} }}
    secondaryButton={{ label: `Deny`, action: () => {} }}
  >
    <Story />
  </Modal>
);

export default {
  title: 'Dashboard/Users/ReviewUnlockRequest', // eslint-disable-line
  component: ReviewUnlockRequest,
  decorators: [inModal],
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof ReviewUnlockRequest>;

const Template: StoryFn<typeof ReviewUnlockRequest> = (args) => (
  <ReviewUnlockRequest {...args} />
);

// @screenshot: xs,md
export const Default = Template.bind({});
Default.args = {
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
  ...Default.args,
  appName: undefined,
};

export const EmptyStringComment = Template.bind({});
EmptyStringComment.args = {
  ...Default.args,
  requestComment: ``,
};
