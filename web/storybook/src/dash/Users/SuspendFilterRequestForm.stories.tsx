import { Modal, SuspendFilterRequestForm } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props, time } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Users/SuspendFilterRequestForm', // eslint-disable-line
  component: SuspendFilterRequestForm,
  decorators: [
    (Story) => (
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
    ),
  ],
} satisfies Meta<typeof SuspendFilterRequestForm>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Default: Story = props({
  username: `Win`,
  requestComment: `Watch some videos for Al's class`,
  requestedDurationInSeconds: 60 * 5,
  requestedAt: time.subtracting({ minutes: 5 }),
  durationInSeconds: `60`,
  customDurationInMinutes: ``,
  responseComment: ``,
  setResponseComment: () => {},
  setDuration: () => {},
  setCustomDuration: () => {},
});

// @screenshot: xs,md
export const CustomDuration: Story = props({
  ...Default.args,
  durationInSeconds: `custom`,
  customDurationInMinutes: `77`,
});

export default meta;
