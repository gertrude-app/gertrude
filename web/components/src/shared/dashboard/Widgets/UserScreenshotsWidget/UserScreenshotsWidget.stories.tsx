import { ComponentStory, ComponentMeta } from '@storybook/react';
import UserScreenshotsWidget from './UserScreenshotsWidget';
import { withIds } from '../../story-helpers';

export default {
  title: `Dashboard/Dashboard/Widgets/UserScreenshotsWidget`,
  component: UserScreenshotsWidget,
} as ComponentMeta<typeof UserScreenshotsWidget>;

const Template: ComponentStory<typeof UserScreenshotsWidget> = (args) => (
  <UserScreenshotsWidget {...args} />
);

const now = new Date();

export const Default = Template.bind({});
Default.args = {
  screenshots: withIds([
    {
      userName: `Little Jimmy`,
      url: `https://placekitten.com/300/200`,
      createdAt: new Date().toISOString(),
    },
    {
      userName: `Sally`,
      url: `https://placekitten.com/400/200`,
      createdAt: new Date(now.getTime() - 1000 * 120).toISOString(),
    },
    {
      userName: `Henry`,
      url: `https://placekitten.com/500/300`,
      createdAt: new Date(now.getTime() - 1000 * 60).toISOString(),
    },
  ]),
};

export const WithWideDisplay = Template.bind({});
WithWideDisplay.args = {
  screenshots: withIds([
    {
      userName: `Little Jimmy`,
      url: `https://placekitten.com/700/200`,
      createdAt: new Date().toISOString(),
    },
    {
      userName: `Sally`,
      url: `https://placekitten.com/400/200`,
      createdAt: new Date(now.getTime() - 1000 * 120).toISOString(),
    },
    {
      userName: `Henry`,
      url: `https://placekitten.com/500/300`,
      createdAt: new Date(now.getTime() - 1000 * 60).toISOString(),
    },
  ]),
};
