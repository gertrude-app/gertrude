import { PillBadge } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';

const PillBadges: React.FC = () => (
  <div className="space-y-6">
    <PillBadge type="info">info</PillBadge>
    <PillBadge type="blue">blue</PillBadge>
    <PillBadge type="ok">ok</PillBadge>
    <PillBadge type="green">green standard</PillBadge>
    <PillBadge type="green" small>
      green small
    </PillBadge>
    <PillBadge type="warning">warning standard</PillBadge>
    <PillBadge type="warning" small>
      warning small
    </PillBadge>
    <PillBadge type="yellow">yellow</PillBadge>
    <PillBadge type="error">error</PillBadge>
    <PillBadge type="red">red</PillBadge>
  </div>
);

const meta = {
  title: 'Dashboard/Core/PillBadge', // eslint-disable-line
  component: PillBadges,
} satisfies Meta<typeof PillBadges>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs
export const List: Story = {};

export default meta;
