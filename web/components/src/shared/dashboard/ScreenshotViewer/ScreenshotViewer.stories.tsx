import { ComponentStory, ComponentMeta } from '@storybook/react';

import ScreenshotViewer from './ScreenshotViewer';

export default {
  title: `ScreenshotViewer`,
  component: ScreenshotViewer,
} as ComponentMeta<typeof ScreenshotViewer>;

const Template: ComponentStory<typeof ScreenshotViewer> = (args) => (
  <ScreenshotViewer {...args} />
);

export const Default = Template.bind({});
Default.args = { image: `https://placekitten.com/800/600`, date: new Date() };

export const Tall = Template.bind({});
Tall.args = { image: `https://placekitten.com/800/900`, date: new Date() };

export const Wide = Template.bind({});
Wide.args = { image: `https://placekitten.com/1200/400`, date: new Date() };
