import { UnlockRequestCard } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props, time } from '../story-helpers';

const meta = {
  title: 'Dashboard/Core/UnlockRequestCard', // eslint-disable-line
  component: UnlockRequestCard,
} satisfies Meta<typeof UnlockRequestCard>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  id: `1`,
  userId: `u1`,
  createdAt: time.stable(),
  userName: `Freddy`,
  url: `github.com`,
  comment: `Pleeeease can I use this? It's sooooo cool`,
  status: `pending`,
});

export const LongComment: Story = props({
  ...Default.args,
  url: `khanacademy.org`,
  comment: `This is just some online courses about math, science, history, economics, and lorem ipsum dolor sit, amet consectetur adipisicing elit. Aspernatur vel molestiae placeat ex, asperiores corporis deserunt. Laborum eligendi doloremque nostrum dolor, corporis nisi, minima pariatur ab officia eaque sequi. Veniam?`,
});

export const Accepted: Story = props({
  ...Default.args,
  status: `accepted`,
});

export const Rejected: Story = props({
  ...Default.args,
  status: `rejected`,
});

export const NoComment: Story = props({
  ...Default.args,
  comment: undefined,
});

export const LongUrl: Story = props({
  ...Default.args,
  url: `abc123xyz.aa__basdfoeihagafhfaskjfwiauefga32433h2h1232_ADfq23r.link`,
});

export default meta;
