import { PageHeading } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Dashboard/Core/PageHeading', // eslint-disable-line
  component: PageHeading,
} satisfies Meta<typeof PageHeading>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  children: `Page heading`,
  icon: `user`,
});

export default meta;
