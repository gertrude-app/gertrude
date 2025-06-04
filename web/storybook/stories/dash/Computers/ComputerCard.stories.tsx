import { ComputerCard } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Computers/ComputerCard', // eslint-disable-line
  component: ComputerCard,
} satisfies Meta<typeof ComputerCard>;

type Story = StoryObj<typeof meta>;

export const WithName: Story = props({
  name: `Silvery`,
  id: `1234`,
  modelTitle: `Mac Studio (2023)`,
  modelIdentifier: `Mac14,14`,
  onlineUser: `Juliet`,
});

export const WithoutName: Story = props({
  ...WithName.args,
  name: undefined,
});

export const Offline: Story = props({
  ...WithName.args,
  onlineUser: undefined,
});

export default meta;
