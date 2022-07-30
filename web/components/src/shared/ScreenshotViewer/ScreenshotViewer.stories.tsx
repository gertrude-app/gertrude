import { ComponentStory, ComponentMeta } from '@storybook/react';

import ScreenshotViewer from './ScreenshotViewer';

export default {
  title: 'ScreenshotViewer',
  component: ScreenshotViewer,
} as ComponentMeta<typeof ScreenshotViewer>;

const Template: ComponentStory<typeof ScreenshotViewer> = (args) => <ScreenshotViewer {...args} />;

export const Default = Template.bind({});
