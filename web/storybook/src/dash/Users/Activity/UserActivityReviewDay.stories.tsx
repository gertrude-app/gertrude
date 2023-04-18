import { UserActivityReviewDay } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import type { ActivityItem } from '@dash/components';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import { props, testImgUrl, time } from '../../../story-helpers';

const meta = {
  title: 'Dashboard/Users/Activity/UserActivityReviewDay', // eslint-disable-line
  component: UserActivityReviewDay,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof UserActivityReviewDay>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  date: new Date(time.stable()),
  items: activity[`Sally`],
  numDeleted: 0,
  deleteItems: () => {},
});

export const Empty: Story = props({
  ...Default.args,
  items: [],
});

// @screenshot: xs,md
export const Chunked: Story = props({
  ...Default.args,
  chunkSize: 3,
  items: [
    keystrokeLine(`Xcode`, `import Foundation`),
    keystrokeLine(`Brave`, `Hello world`),
    screenshot(700, 200),
    keystrokeLine(`Xcode`, `import Foundation`),
    screenshot(700, 200),
    keystrokeLine(`Brave`, `Hello world`),
    screenshot(700, 200),
    screenshot(700, 200),
    keystrokeLine(`Xcode`, `import Foundation`),
  ],
});

// helpers

function common(): { id: string; ids: string[]; date: string } {
  const current = `item-${Math.random()}`;
  return {
    id: `${current}`,
    ids: [`${current}`],
    date: time.stable(),
  };
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

function screenshot(width = 800, height = 600, deleted?: boolean): ActivityItem {
  return {
    ...common(),
    type: `Screenshot`,
    url: testImgUrl(width, height),
    width,
    height,
    deleted,
  };
}

export default meta;
