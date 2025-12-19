import { Badge } from '@shared/components';
import type { Meta, StoryObj } from '@storybook/react';

const Badges: React.FC = () => (
  <div className="space-y-6">
    <Badge type="info" size="large">
      blue large
    </Badge>
    <Badge type="blue" size="medium">
      blue medium
    </Badge>
    <Badge type="blue" size="small">
      blue small
    </Badge>
    <Badge type="green" size="large">
      green large
    </Badge>
    <Badge type="green" size="medium">
      green medium
    </Badge>
    <Badge type="green" size="small">
      green small
    </Badge>
    <Badge type="yellow" size="large">
      yellow large
    </Badge>
    <Badge type="yellow" size="medium">
      yellow medium
    </Badge>
    <Badge type="yellow" size="small">
      yellow small
    </Badge>
    <Badge type="red" size="large">
      red large
    </Badge>
    <Badge type="red" size="medium">
      red medium
    </Badge>
    <Badge type="red" size="small">
      red small
    </Badge>
  </div>
);

const meta = {
  title: 'Dashboard/Core/Badge', // eslint-disable-line
  component: Badges,
} satisfies Meta<typeof Badges>;

type Story = StoryObj<typeof meta>;

export const List: Story = {};

export default meta;
