import { UnlockRequestCard } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';
import { time } from '../story-helpers';

export default {
  title: 'Dashboard/Core/UnlockRequestCard', // eslint-disable-line
  component: UnlockRequestCard,
  screenshot: `xs`,
} as ComponentMeta<typeof UnlockRequestCard>;

const Template: StoryFn<typeof UnlockRequestCard> = (args) => (
  <UnlockRequestCard {...args} />
);

export const Default = Template.bind({});
Default.args = {
  createdAt: new Date(time.stable()).toISOString(),
  userName: `Freddy`,
  url: `github.com`,
  comment: `Pleeeease can I use this? It's sooooo cool`,
  status: `pending`,
};

export const LongComment = Template.bind({});
LongComment.args = {
  ...Default.args,
  url: `khanacademy.org`,
  comment: `This is just some online courses about math, science, history, economics, and lorem ipsum dolor sit, amet consectetur adipisicing elit. Aspernatur vel molestiae placeat ex, asperiores corporis deserunt. Laborum eligendi doloremque nostrum dolor, corporis nisi, minima pariatur ab officia eaque sequi. Veniam?`,
};

export const Accepted = Template.bind({});
Accepted.args = {
  ...Default.args,
  status: `accepted`,
};

export const Rejected = Template.bind({});
Rejected.args = {
  ...Default.args,
  status: `rejected`,
};

export const NoComment = Template.bind({});
NoComment.args = {
  ...Default.args,
  comment: undefined,
};

export const LongUrl = Template.bind({});
LongUrl.args = {
  ...Default.args,
  url: `abc123xyz.aa__basdfoeihagafhfaskjfwiauefga32433h2h1232_ADfq23r.link`,
};
