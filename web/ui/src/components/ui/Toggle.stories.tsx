import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type { ComponentProps, FC } from 'react';
import Toggle from './Toggle';
import {
  StoryCanvas,
  StorySection,
  galleryParameters,
  useSyncedStoryState,
} from '#/storybook/StoryLayout';

type ToggleProps = ComponentProps<typeof Toggle>;
type StatefulToggleProps = Omit<ToggleProps, `setChecked`>;

const StatefulToggle: FC<StatefulToggleProps> = ({ checked, ...args }) => {
  const [currentChecked, setCurrentChecked] = useSyncedStoryState(checked);

  return <Toggle {...args} checked={currentChecked} setChecked={setCurrentChecked} />;
};

const meta = {
  title: 'UI/Toggle',
  component: Toggle,
  args: { checked: true, setChecked: () => undefined },
  argTypes: {
    checked: { control: `boolean` },
    disabled: { control: `boolean` },
    small: { control: `boolean` },
    setChecked: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Toggle>;

export default meta;

type Story = StoryObj<typeof meta>;

export const States: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Medium">
        <LabeledToggle label="on" checked />
        <LabeledToggle label="off" checked={false} />
        <LabeledToggle label="on disabled" checked disabled />
        <LabeledToggle label="off disabled" checked={false} disabled />
      </StorySection>
      <StorySection title="Small">
        <LabeledToggle label="small on" checked small />
        <LabeledToggle label="small off" checked={false} small />
        <LabeledToggle label="small disabled" checked disabled small />
      </StorySection>
    </StoryCanvas>
  ),
};

type LabeledToggleProps = StatefulToggleProps & {
  label: string;
};

const LabeledToggle: FC<LabeledToggleProps> = ({ label, ...props }) => (
  <div className="grid gap-2">
    <span className="font-mono text-xs text-stone-500">{label}</span>
    <StatefulToggle {...props} />
  </div>
);
