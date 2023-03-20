import { ScreenshotViewer } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';
import { testImgUrl, time } from '../../../story-helpers';

export default {
  title: 'Dashboard/Users/Activity/ScreenshotViewer', // eslint-disable-line
  component: ScreenshotViewer,
} as ComponentMeta<typeof ScreenshotViewer>;

const Template: StoryFn<typeof ScreenshotViewer> = (args) => (
  <ScreenshotViewer {...args} />
);

export const Default = Template.bind({});
Default.args = {
  url: testImgUrl(800, 600),
  width: 800,
  height: 600,
  date: new Date(time.stable()),
};

export const Tall = Template.bind({});
Tall.args = {
  ...Default.args,
  url: testImgUrl(800, 900),
  width: 800,
  height: 900,
};

export const Wide = Template.bind({});
Wide.args = {
  ...Default.args,
  url: testImgUrl(1200, 400),
  width: 1200,
  height: 400,
};
