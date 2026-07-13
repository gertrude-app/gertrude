import { UserScreenshotsWidget } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props, testImgUrl, time, withIds } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Dashboard/Widgets/ChildScreenshots',
  component: UserScreenshotsWidget,
} satisfies Meta<typeof UserScreenshotsWidget>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  screenshots: withIds([
    {
      childName: `Little Jimmy`,
      url: testImgUrl(300, 200),
      createdAt: time.now(),
    },
    {
      childName: `Sally`,
      url: testImgUrl(400, 200),
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      childName: `Henry`,
      url: testImgUrl(500, 300),
      createdAt: time.subtracting({ minutes: 4 }),
    },
  ]),
});

export const WithWideDisplay: Story = props({
  screenshots: withIds([
    {
      childName: `Little Jimmy`,
      url: testImgUrl(700, 200),
      createdAt: time.now(),
    },
    {
      childName: `Sally`,
      url: testImgUrl(400, 200),
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      childName: `Henry`,
      url: testImgUrl(500, 300),
      createdAt: time.subtracting({ minutes: 4 }),
    },
  ]),
});

export default meta;
