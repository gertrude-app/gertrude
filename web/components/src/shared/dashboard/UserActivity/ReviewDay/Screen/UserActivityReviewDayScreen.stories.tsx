import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../../../decorators/StatefulChrome';
import UserActivityReviewDayScreen, { ActivityItem } from './UserActivityReviewDayScreen';

export default {
  title: `Dashboard/UserActivity/ReviewDayScreen`,
  component: UserActivityReviewDayScreen,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof UserActivityReviewDayScreen>;

const Template: ComponentStory<typeof UserActivityReviewDayScreen> = (args) => (
  <UserActivityReviewDayScreen {...args} />
);

export const Default = Template.bind({});
Default.args = {
  date: new Date(),
  numReviewedItems: 0,
  items: [
    keystrokeLine(`Brave`, `Hello world`),
    keystrokeLine(`Xcode`, `import Foundation`),
    screenshot(),
    screenshot(),
  ],
};

export const Empty = Template.bind({});
Empty.args = { ...Default.args, items: [] };

// helpers

function common(): { id: string; ids: string[]; date: string } {
  const current = `item-${Math.random()}`;
  return { id: `${current}`, ids: [`${current}`], date: new Date().toISOString() };
}

function keystrokeLine(appName: string, line: string): ActivityItem {
  return {
    ...common(),
    type: `KeystrokeLine`,
    appName,
    line,
  };
}

function screenshot(width = 800, height = 270): ActivityItem {
  return {
    ...common(),
    type: `Screenshot`,
    url: `https://placekitten.com/${width}/${height}`,
    width,
    height,
  };
}
