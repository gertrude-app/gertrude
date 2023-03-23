import { VideoModal } from '@site/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Site/VideoModal', // eslint-disable-line
  component: VideoModal,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof VideoModal>;

const Template: StoryFn<typeof VideoModal> = (args) => <VideoModal {...args} />;

export const Default = Template.bind({});
Default.args = {
  onDismiss: () => {},
  videoId: `QgwxbbtA4wo`,
};
