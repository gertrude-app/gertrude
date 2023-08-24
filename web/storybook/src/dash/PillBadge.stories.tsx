import { PillBadge } from '@shared/components';
import type { StoryObj, Meta } from '@storybook/react';

const PillBadges: React.FC = () => (
  <div className="space-y-6">
    <PillBadge type="info" size="large">
      blue large
    </PillBadge>
    <PillBadge type="blue" size="medium">
      blue medium
    </PillBadge>
    <PillBadge type="blue" size="small">
      blue small
    </PillBadge>
    <PillBadge type="green" size="large">
      green large
    </PillBadge>
    <PillBadge type="green" size="medium">
      green medium
    </PillBadge>
    <PillBadge type="green" size="small">
      green small
    </PillBadge>
    <PillBadge type="yellow" size="large">
      yellow large
    </PillBadge>
    <PillBadge type="yellow" size="medium">
      yellow medium
    </PillBadge>
    <PillBadge type="yellow" size="small">
      yellow small
    </PillBadge>
    <PillBadge type="red" size="large">
      red large
    </PillBadge>
    <PillBadge type="red" size="medium">
      red medium
    </PillBadge>
    <PillBadge type="red" size="small">
      red small
    </PillBadge>
  </div>
);

const meta = {
  title: 'Dashboard/Core/PillBadge', // eslint-disable-line
  component: PillBadges,
} satisfies Meta<typeof PillBadges>;

type Story = StoryObj<typeof meta>;

export const List: Story = {};

export default meta;
