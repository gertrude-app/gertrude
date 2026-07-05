import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type { ComponentProps, FC } from 'react';
import Checkbox from './Checkbox';
import {
  StoryCanvas,
  StorySection,
  galleryParameters,
  useSyncedStoryState,
} from '#/storybook/StoryLayout';

type CheckboxProps = ComponentProps<typeof Checkbox>;
type StatefulCheckboxProps = Omit<CheckboxProps, `setChecked`>;

const StatefulCheckbox: FC<StatefulCheckboxProps> = ({ checked, ...args }) => {
  const [currentChecked, setCurrentChecked] = useSyncedStoryState(checked);

  return <Checkbox {...args} checked={currentChecked} setChecked={setCurrentChecked} />;
};

const meta = {
  title: 'UI/Components/Checkbox',
  component: Checkbox,
  args: { checked: false, setChecked: () => undefined },
  argTypes: {
    checked: { control: `boolean` },
    label: { control: `text` },
    description: { control: `text` },
    indeterminate: { control: `boolean` },
    disabled: { control: `boolean` },
    ariaLabel: { control: false },
    id: { control: false },
    name: { control: false },
    setChecked: { control: false },
    value: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Checkbox>;

export default meta;

type Story = StoryObj<typeof meta>;

export const States: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Unchecked">
        <StatefulCheckbox checked={false} label="Off" />
        <StatefulCheckbox
          checked={false}
          label="Off with description"
          description="Extra helper text sits below the label."
        />
      </StorySection>
      <StorySection title="Checked">
        <StatefulCheckbox checked label="On" />
        <StatefulCheckbox
          checked
          label="On with description"
          description="The label and description remain clickable."
        />
      </StorySection>
      <StorySection title="Indeterminate">
        <StatefulCheckbox checked={false} indeterminate label="Mixed selection" />
        <StatefulCheckbox
          checked
          indeterminate
          label="Mixed from checked"
          description="The visual state takes precedence over checked."
        />
      </StorySection>
      <StorySection title="Disabled">
        <Checkbox checked setChecked={() => undefined} label="Locked on" disabled />
        <Checkbox
          checked={false}
          setChecked={() => undefined}
          label="Locked off"
          disabled
        />
      </StorySection>
    </StoryCanvas>
  ),
};
