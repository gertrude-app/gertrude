import { Toggle } from '@shared/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Shared/Toggle', // eslint-disable-line
  component: Toggle,
  parameters: { layout: `centered` },
} satisfies Meta<typeof Toggle>;

type Story = StoryObj<typeof meta>;

export const DefaultDisabled: Story = props({
  small: false,
  enabled: false,
  setEnabled: () => {},
});

export const DefaultEnabled: Story = props({
  small: false,
  enabled: true,
  setEnabled: () => {},
});

export const SmallDisabled: Story = props({
  small: true,
  enabled: false,
  setEnabled: () => {},
});

export const SmallEnabled: Story = props({
  small: true,
  enabled: true,
  setEnabled: () => {},
});

export default meta;
