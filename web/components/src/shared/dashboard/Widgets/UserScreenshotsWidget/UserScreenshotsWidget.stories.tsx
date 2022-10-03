import { ComponentStory, ComponentMeta } from '@storybook/react';
import UserScreenshotsWidget from './UserScreenshotsWidget';

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
  userScreenshots: [
    {
      userName: 'Little Jimmy',
      img: 'https://placekitten.com/300/200',
      app: 'Firefox',
      time: new Date(),
    },
    {
      userName: 'Sally',
      img: 'https://placekitten.com/400/200',
      app: 'Figma',
      time: new Date(now.getTime() - 1000 * 120),
    },
    {
      userName: 'Henry',
      img: 'https://placekitten.com/500/300',
      app: 'Notes',
      time: new Date(now.getTime() - 1000 * 60),
    },
  ],
};

export const WithWideDisplay = Template.bind({});
WithWideDisplay.args = {
  userScreenshots: [
    {
      userName: 'Little Jimmy',
      img: 'https://placekitten.com/700/200',
      app: 'Firefox',
      time: new Date(),
    },
    {
      userName: 'Sally',
      img: 'https://placekitten.com/400/200',
      app: 'Figma',
      time: new Date(now.getTime() - 1000 * 120),
    },
    {
      userName: 'Henry',
      img: 'https://placekitten.com/500/300',
      app: 'Notes',
      time: new Date(now.getTime() - 1000 * 60),
    },
  ],
};
