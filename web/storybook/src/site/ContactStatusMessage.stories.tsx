import { ContactStatusMessage } from '@site/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Site/ContactStatusMessage', // eslint-disable-line
  component: ContactStatusMessage,
} satisfies Meta<typeof ContactStatusMessage>;

type Story = StoryObj<typeof meta>;

export const Info: Story = props({
  type: `info`,
  heading: `Just FYI...`,
  message: `Lorem ipsum dolor sit amet consectetur adipisicing elit.`,
});

export const Success: Story = props({
  type: `success`,
  heading: `Something went right!`,
  message: `Lorem ipsum dolor sit amet consectetur adipisicing elit.`,
});

export const Warning: Story = props({
  type: `warning`,
  heading: `Hmmm...`,
  message: `Lorem ipsum dolor sit amet consectetur adipisicing elit.`,
});

export const Error: Story = props({
  type: `error`,
  heading: `Uh-oh, something awful happened`,
  message: `Lorem ipsum dolor sit amet consectetur adipisicing elit.`,
});

export default meta;
