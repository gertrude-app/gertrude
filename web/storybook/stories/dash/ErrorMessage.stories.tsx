import { ErrorMessage } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Dashboard/Core/ErrorMessage', // eslint-disable-line
  component: ErrorMessage,
} satisfies Meta<typeof ErrorMessage>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  children: `Something went wrong!`,
});

export const LongMessage: Story = props({
  children: `EADDRINUSE: Really sorry about this, but it seems like something (or several things) went wrong! Maybe you should check the specs on the rotary girder!`,
});

export default meta;
