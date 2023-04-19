import { VideoModal } from '@site/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Site/VideoModal', // eslint-disable-line
  component: VideoModal,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof VideoModal>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  onDismiss: () => {},
  videoId: `QgwxbbtA4wo`,
});

export default meta;
