import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../../decorators/StatefulChrome';
import WidgetsContainer from './WidgetsContainer';

export default {
  title: `Dashboard/Dashboard/WidgetsContainer`,
  component: WidgetsContainer,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof WidgetsContainer>;

const Template: ComponentStory<typeof WidgetsContainer> = (args) => (
  <WidgetsContainer {...args} />
);

const now = new Date();
export const Default = Template.bind({});
Default.args = {
  unlockRequests: [
    {
      url: `gitlab.io`,
      user: `Little Jimmy`,
      comment: `Super cool thing I want`,
      time: new Date(now.getTime() - 0), // now
    },
    {
      url: `goats.com`,
      user: `Henry`,
      time: new Date(now.getTime() - 1000 * 120), // 2 minutes ago
    },
    {
      url: `github.com`,
      user: `Little Jimmy`,
      time: new Date(now.getTime() - 1000 * 60 * 60 * 24), // 1 day ago
    },
    {
      url: `magicschoolbus.com`,
      user: `Sally`,
      comment: `For science class, thanks ❤️`,
      time: new Date(now.getTime() - 1000 * 60 * 60 * 24 * 7 * 2), // 2 weeks ago
    },
  ],
  users: [
    { name: `Little Jimmy`, online: true },
    { name: `Sally`, online: true },
    { name: `Henry`, online: false },
  ],
  userActivity: [
    { user: 'Little Jimmy', unreviewedItems: 245 },
    { user: 'Sally', unreviewedItems: 0 },
    { user: 'Henry', unreviewedItems: 23 },
  ],
};

export const NoUnlockRequests = Template.bind({});
NoUnlockRequests.args = {
  ...Default.args,
  unlockRequests: [],
};
