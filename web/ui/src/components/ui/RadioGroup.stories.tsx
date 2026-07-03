import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type { ComponentProps, FC } from 'react';
import RadioGroup from './RadioGroup';
import {
  StoryCanvas,
  StorySection,
  galleryParameters,
  useSyncedStoryState,
} from '#/storybook/StoryLayout';

const ruleModes = [`Homework first`, `Bedtime`, `Weekend`] as const;
const durations = [`Today`, `This week`, `Always`] as const;

type RadioGroupProps = ComponentProps<typeof RadioGroup>;

const StatefulRadioGroup: FC<RadioGroupProps> = ({ selected, ...args }) => {
  const [currentSelected, setCurrentSelected] = useSyncedStoryState(selected);

  return (
    <RadioGroup {...args} selected={currentSelected} setSelected={setCurrentSelected} />
  );
};

const meta = {
  title: 'UI/RadioGroup',
  component: RadioGroup,
  args: {
    selected: `Homework first`,
    setSelected: () => undefined,
    possibleValues: [...ruleModes],
  },
  argTypes: {
    selected: { options: ruleModes, control: { type: `inline-radio` } },
    label: { control: `text` },
    direction: { options: [`vertical`, `horizontal`], control: { type: `inline-radio` } },
    disabled: { control: `boolean` },
    ariaLabel: { control: false },
    name: { control: false },
    possibleValues: { control: false },
    setSelected: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof RadioGroup>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection
        title="Layouts"
        contentClassName="grid items-start gap-8 sm:grid-cols-3"
      >
        <StatefulRadioGroup
          label="Rule mode"
          selected="Homework first"
          setSelected={() => undefined}
          possibleValues={[...ruleModes]}
        />
        <StatefulRadioGroup
          label="Duration"
          direction="horizontal"
          selected="Today"
          setSelected={() => undefined}
          possibleValues={[...durations]}
        />
        <StatefulRadioGroup
          label="Managed setting"
          selected="School profile"
          setSelected={() => undefined}
          possibleValues={[`Parent setting`, `School profile`]}
          disabled
        />
      </StorySection>
      <StorySection title="Without visible label">
        <StatefulRadioGroup
          ariaLabel="Notification preference"
          direction="horizontal"
          selected="Email"
          setSelected={() => undefined}
          possibleValues={[`Email`, `Push`, `None`]}
        />
      </StorySection>
    </StoryCanvas>
  ),
};
