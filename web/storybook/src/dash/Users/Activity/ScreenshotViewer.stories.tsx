import { ScreenshotViewer } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { testImgUrl, time, props } from '../../../story-helpers';

const meta = {
  title: 'Dashboard/Users/Activity/ScreenshotViewer', // eslint-disable-line
  component: ScreenshotViewer,
} satisfies Meta<typeof ScreenshotViewer>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  url: testImgUrl(800, 600),
  width: 800,
  height: 600,
  date: new Date(time.stable()),
});

export const Tall: Story = props({
  ...Default.args,
  url: testImgUrl(800, 900),
  width: 800,
  height: 900,
});

export const Wide: Story = props({
  ...Default.args,
  url: testImgUrl(1200, 400),
  width: 1200,
  height: 400,
});

export default meta;
