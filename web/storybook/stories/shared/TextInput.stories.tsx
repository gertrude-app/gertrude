import { TextInput } from '@shared/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Shared/TextInput', // eslint-disable-line
  component: TextInput,
  decorators: [(story) => <div className="max-w-sm">{story()}</div>],
} satisfies Meta<typeof TextInput>;

type Story = StoryObj<typeof TextInput>;

export const Default: Story = props({
  type: `email`,
  label: `Email address`,
  placeholder: `you@example.com`,
  value: ``,
  setValue: () => {},
});

export const WithUnit: Story = props({
  ...Default.args,
  type: `positiveInteger`,
  label: `Interval`,
  unit: `seconds`,
});

export const WithPrefix: Story = props({
  ...Default.args,
  type: `text`,
  label: `URL`,
  prefix: `https://`,
});

export const WithUnitAndPrefix: Story = props({
  ...WithPrefix.args,
  label: `Web address`,
  unit: `.com`,
});

export default meta;
