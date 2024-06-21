import { UserActivityFeed } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { withStatefulChrome } from '../../../decorators/StatefulChrome';
import { activity, keystrokeLine, props, screenshot, time } from '../../../story-helpers';

const meta = {
  title: 'Dashboard/Users/Activity/UserActivityReviewDay', // eslint-disable-line
  component: UserActivityFeed,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof UserActivityFeed>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  date: new Date(time.stable()),
  items: activity[2]?.items ?? [],
  numDeleted: 0,
  highlightSuspensionActivity: true,
  deleteItems: () => {},
});

// @screenshot: xs,md
export const WithSuspensions: Story = props({
  ...Default.args,
  items: [
    keystrokeLine(`VSCode`, `import React from 'react';`, false, false),
    keystrokeLine(`Arc`, `why did twitter change to x?`, false, true),
    screenshot(800, 600, false, true),
    keystrokeLine(
      `Notion`,
      `everybody say hi to our new team member, @curdie`,
      false,
      true,
    ),
    screenshot(500, 300, false, true),
    keystrokeLine(`VSCode`, `import React from 'react';`, false, false),
    keystrokeLine(`Arc`, `why did twitter change to x?`, false, false),
    screenshot(800, 600, false, true),
    keystrokeLine(
      `Notion`,
      `everybody say hi to our new team member, @curdie`,
      false,
      true,
    ),
    screenshot(700, 200, false, false),
    keystrokeLine(
      `Notion`,
      `everybody say hi to our new team member, @curdie`,
      false,
      true,
    ),
  ],
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

export default meta;
