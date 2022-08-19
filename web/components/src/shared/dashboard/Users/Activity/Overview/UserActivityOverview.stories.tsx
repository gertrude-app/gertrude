import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../../../decorators/StatefulChrome';
import UserActivityOverview from '.';

export default {
  title: `Dashboard/Users/Activity/Overview`,
  component: UserActivityOverview,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof UserActivityOverview>;

const Template: ComponentStory<typeof UserActivityOverview> = (args) => (
  <UserActivityOverview {...args} />
);

export const Default = Template.bind({});
Default.args = {
  userName: `Little Jimmy`,
  days: [
    { date: new Date(), numItems: 330, numCompleted: 0 },
    { date: new Date(), numItems: 117, numCompleted: 64 },
    { date: new Date(), numItems: 89, numCompleted: 89 },
    { date: new Date(), numItems: 1317, numCompleted: 1317 },
  ],
};

export const Empty = Template.bind({});
Empty.args = {
  ...Default.args,
  days: [],
};
