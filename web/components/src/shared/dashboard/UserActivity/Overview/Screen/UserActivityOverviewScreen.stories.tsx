import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../../../decorators/StatefulChrome';
import UserActivityOverviewScreen from './UserActivityOverviewScreen';

export default {
  title: `Dashboard/UserActivity/OverviewScreen`,
  component: UserActivityOverviewScreen,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof UserActivityOverviewScreen>;

const Template: ComponentStory<typeof UserActivityOverviewScreen> = (args) => (
  <UserActivityOverviewScreen {...args} />
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
