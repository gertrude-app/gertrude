import { UserScreenshotsWidget } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { withIds, props, time, testImgUrl } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Dashboard/Widgets/UserScreenshots', // eslint-disable-line
  component: UserScreenshotsWidget,
} satisfies Meta<typeof UserScreenshotsWidget>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  screenshots: withIds([
    {
      userName: `Little Jimmy`,
      url: testImgUrl(300, 200),
      createdAt: time.now(),
    },
    {
      userName: `Sally`,
      url: testImgUrl(400, 200),
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      userName: `Henry`,
      url: testImgUrl(500, 300),
      createdAt: time.subtracting({ minutes: 4 }),
    },
  ]),
});

export const WithWideDisplay: Story = props({
  screenshots: withIds([
    {
      userName: `Little Jimmy`,
      url: testImgUrl(700, 200),
      createdAt: time.now(),
    },
    {
      userName: `Sally`,
      url: testImgUrl(400, 200),
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      userName: `Henry`,
      url: testImgUrl(500, 300),
      createdAt: time.subtracting({ minutes: 4 }),
    },
  ]),
});

export default meta;
