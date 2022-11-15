import { UserActivityReviewDay } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import type { ActivityItem } from '@dash/components';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import { testImgUrl } from '../../../story-helpers';

export default {
  title: 'Dashboard/Users/Activity/UserActivityReviewDay', // eslint-disable-line
  component: UserActivityReviewDay,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof UserActivityReviewDay>;

const Template: ComponentStory<typeof UserActivityReviewDay> = (args) => (
  <UserActivityReviewDay {...args} />
);

export const Default = Template.bind({});
Default.args = {
  date: new Date(),
  items: [
    keystrokeLine(
      `Xcode`,
      `importFoundationhereisareallylonglinethatwillcauseproblemspotentiallyblahblahblahlorem`,
    ),
    screenshot(400, 600, true),
    keystrokeLine(`Brave`, `Hello world`),
    keystrokeLine(`Xcode`, `import Foundation`),
    screenshot(),
    screenshot(),
  ],
  numDeleted: 0,
  deleteItems: () => {},
};

export const Empty = Template.bind({});
Empty.args = { ...Default.args, items: [] };

export const Chunked = Template.bind({});
Chunked.args = {
  ...Default.args,
  chunkSize: 3,
  items: [
    keystrokeLine(`Xcode`, `import Foundation`),
    keystrokeLine(`Brave`, `Hello world`),
    screenshot(600, 200),
    keystrokeLine(`Xcode`, `import Foundation`),
    screenshot(600, 200),
    keystrokeLine(`Brave`, `Hello world`),
    screenshot(600, 200),
    screenshot(600, 200),
    keystrokeLine(`Xcode`, `import Foundation`),
  ],
};

// helpers

function common(): { id: string; ids: string[]; date: string } {
  const current = `item-${Math.random()}`;
  return { id: `${current}`, ids: [`${current}`], date: new Date().toISOString() };
}

function keystrokeLine(appName: string, line: string, deleted?: boolean): ActivityItem {
  return {
    ...common(),
    type: `KeystrokeLine`,
    appName,
    line,
    deleted,
  };
}

function screenshot(width = 800, height = 270, deleted?: boolean): ActivityItem {
  return {
    ...common(),
    type: `Screenshot`,
    url: testImgUrl(width, height),
    width,
    height,
    deleted,
  };
}
