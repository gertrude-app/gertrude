import { NotificationMethod } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Settings/NotificationMethod', // eslint-disable-line
  component: NotificationMethod,
} satisfies Meta<typeof NotificationMethod>;

type Story = StoryObj<typeof meta>;

export const Email: Story = props({
  method: `email`,
  value: `me@example.com`,
  deletable: true,
  inUse: true,
  createNotification: () => {},
  onDelete: () => {},
});

export const Text: Story = props({
  ...Email.args,
  method: `text`,
  value: `+1 (555) 555-5555`,
});

export const Slack: Story = props({
  ...Email.args,
  method: `slack`,
  value: `#Gertrude`,
});

export const NotInUse: Story = props({
  ...Email.args,
  inUse: false,
});

export default meta;
