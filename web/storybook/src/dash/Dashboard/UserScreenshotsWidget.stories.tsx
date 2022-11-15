import { UserScreenshotsWidget } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { withIds, time, testImgUrl } from '../../story-helpers';

export default {
  title: 'Dashboard/Dashboard/Widgets/UserScreenshots', // eslint-disable-line
  component: UserScreenshotsWidget,
} as ComponentMeta<typeof UserScreenshotsWidget>;

const Template: ComponentStory<typeof UserScreenshotsWidget> = (args) => (
  <UserScreenshotsWidget {...args} />
);

export const Default = Template.bind({});
Default.args = {
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
};

export const WithWideDisplay = Template.bind({});
WithWideDisplay.args = {
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
};
