import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../../decorators/StatefulChrome';
import WidgetsContainer from './WidgetsContainer';

export default {
  title: `Dashboard/Dashboard/WidgetsContainer`,
  component: WidgetsContainer,
  decorators: [withStatefulChrome],
  parameters: { layout: 'fullscreen' },
} as ComponentMeta<typeof WidgetsContainer>;

const Template: ComponentStory<typeof WidgetsContainer> = (args) => (
  <WidgetsContainer {...args} />
);

export const Default = Template.bind({});
Default.args = {
  unlockRequests: [
    {
      url: 'gitlab.io',
      user: 'Little Jimmy',
      comment: 'Super cool thing I want',
      time: new Date(),
    },
    {
      url: 'goats.com',
      user: 'Henry',
      time: new Date(),
    },
    {
      url: 'github.com',
      user: 'Little Jimmy',
      comment: 'Just gotta gotta have this one too',
      time: new Date(),
    },
    {
      url: 'magicschoolbus.com',
      user: 'Sally',
      comment: 'For science class, thanks ❤️',
      time: new Date(),
    },
  ],
  users: [
    { name: 'Little Jimmy', online: true },
    { name: 'Sally', online: true },
    { name: 'Henry', online: false },
  ],
};

export const NoUnlockRequests = Template.bind({});
NoUnlockRequests.args = {
  ...Default.args,
  unlockRequests: [],
};
