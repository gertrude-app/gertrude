import { UserScreenshotsWidget } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { withIds, time } from '../../story-helpers';

export default {
  title: `Dashboard/Dashboard/Widgets/UserScreenshots`,
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
      url: `https://placekitten.com/300/200`,
      createdAt: time.now(),
    },
    {
      userName: `Sally`,
      url: `https://placekitten.com/400/200`,
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      userName: `Henry`,
      url: `https://placekitten.com/500/300`,
      createdAt: time.subtracting({ minutes: 4 }),
    },
  ]),
};

export const WithWideDisplay = Template.bind({});
WithWideDisplay.args = {
  screenshots: withIds([
    {
      userName: `Little Jimmy`,
      url: `https://placekitten.com/700/200`,
      createdAt: time.now(),
    },
    {
      userName: `Sally`,
      url: `https://placekitten.com/400/200`,
      createdAt: time.subtracting({ minutes: 2 }),
    },
    {
      userName: `Henry`,
      url: `https://placekitten.com/500/300`,
      createdAt: time.subtracting({ minutes: 4 }),
    },
  ]),
};
