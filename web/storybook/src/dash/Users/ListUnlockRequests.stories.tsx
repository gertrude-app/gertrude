import { ListUnlockRequests } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { withIdsAnd, time } from '../../story-helpers';

export default {
  title: 'Dashboard/Users/ListUnlockRequests', // eslint-disable-line
  component: ListUnlockRequests,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof ListUnlockRequests>;

const Template: StoryFn<typeof ListUnlockRequests> = (args) => (
  <ListUnlockRequests {...args} />
);

// @screenshot: xs,md
export const Default = Template.bind({});
Default.args = {
  requests: withIdsAnd({ userId: `user1` }, [
    {
      userName: `Huck`,
      url: `khanacademy.org`,
      comment: `i'm thirsty for some computer programming`,
      status: `accepted` as const,
      createdAt: time.subtracting({ hours: 3 }),
    },
    {
      userName: `Freddy`,
      url: `github.com`,
      comment: `Pleeeease can I use this? It's sooooo cool`,
      status: `pending` as const,
      createdAt: time.subtracting({ minutes: 3 }),
    },
    {
      userName: `Sally`,
      url: `gitlab.com`,
      comment: `I need this for my job`,
      status: `pending` as const,
      createdAt: time.subtracting({ hours: 1 }),
    },
    {
      userName: `Winfield`,
      url: `gitlab.com`,
      comment: `Need to research whales for Al`,
      status: `rejected` as const,
      createdAt: time.subtracting({ hours: 4 }),
    },
  ]),
};

export const Empty = Template.bind({});
Empty.args = {
  ...Default.args,
  requests: [],
};
