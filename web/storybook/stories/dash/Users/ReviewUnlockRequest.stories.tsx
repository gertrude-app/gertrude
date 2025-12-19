import { Modal, ReviewUnlockRequest } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props, time } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Users/ReviewUnlockRequest', // eslint-disable-line
  component: ReviewUnlockRequest,
  decorators: [
    (Story) => (
      <Modal
        type="container"
        title="Unlock Request"
        icon="unlock"
        primaryButton={{ label: `Accept`, action: () => {} }}
        secondaryButton={{ label: `Deny`, action: () => {} }}
      >
        <Story />
      </Modal>
    ),
  ],
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof ReviewUnlockRequest>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Default: Story = props({
  id: `1`,
  userId: `user1`,
  status: `pending`,
  userName: `Winfield`,
  requestComment: `schedule mayra appointments`,
  url: `https://cdn-s.acuityscheduling.com/logo24613730.jpg?1650316493&whiteBg=1&rectangular=1`,
  domain: `cdn-s.acuityscheduling.com`,
  ipAddress: `151.101.2.132`,
  createdAt: time.subtracting({ minutes: 36 }),
  appName: `Safari Browser`,
  appCategories: [`browser`],
  appBundleId: `.com.apple.Safari`,
  detailsExpanded: false,
  setDetailsExpanded: () => {},
});

export const NoAppName: Story = props({
  ...Default.args,
  appName: undefined,
});

export const EmptyStringComment: Story = props({
  ...Default.args,
  requestComment: ``,
});

export default meta;
