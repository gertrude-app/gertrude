import { Loading } from '@shared/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Shared/Loading', // eslint-disable-line
  component: Loading,
  parameters: {
    layout: `centered`,
  },
} satisfies Meta<typeof Loading>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({});

export default meta;
