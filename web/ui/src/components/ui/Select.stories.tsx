import {
  CalendarDaysIcon,
  ClockIcon,
  MoonIcon,
  ShieldCheckIcon,
  SunIcon,
  UserIcon,
} from 'lucide-react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type { ComponentProps, FC } from 'react';
import Select from './Select';
import {
  StoryCanvas,
  StorySection,
  galleryParameters,
  useSyncedStoryState,
} from '#/storybook/StoryLayout';

const childOptions = [`Sally`, `Franny`, `Jimmy`] as const;
const windowOptions = [
  {
    value: `morning`,
    label: `Morning`,
    description: `Before school starts.`,
    icon: SunIcon,
  },
  {
    value: `afterSchool`,
    label: `After school`,
    description: `Until dinner time.`,
    icon: ClockIcon,
  },
  {
    value: `evening`,
    label: `Evening`,
    description: `After dinner hours.`,
    icon: MoonIcon,
  },
  {
    value: `weekend`,
    label: `Weekend`,
    description: `Saturday and Sunday.`,
    icon: CalendarDaysIcon,
  },
] as const;

type SelectProps = ComponentProps<typeof Select>;

const StatefulSelect: FC<SelectProps> = ({ selected, ...args }) => {
  const [currentSelected, setCurrentSelected] = useSyncedStoryState(selected);

  return <Select {...args} selected={currentSelected} setSelected={setCurrentSelected} />;
};

const meta = {
  title: 'UI/Select',
  component: Select,
  args: {
    selected: `Sally`,
    setSelected: () => undefined,
    possibleValues: [...childOptions],
  },
  argTypes: {
    selected: { options: childOptions, control: { type: `inline-radio` } },
    label: { control: `text` },
    labelPosition: { options: [`top`, `left`], control: { type: `inline-radio` } },
    size: { options: [`small`, `medium`], control: { type: `inline-radio` } },
    disabled: { control: `boolean` },
    className: { control: false },
    possibleValues: { control: false },
    setSelected: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Select>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection
        title="Common selects"
        contentClassName="grid items-end gap-5 sm:grid-cols-3"
      >
        <StatefulSelect
          label="Small child"
          selected="Sally"
          setSelected={() => undefined}
          possibleValues={[...childOptions]}
          size="small"
        />
        <StatefulSelect
          label="Window"
          selected="afterSchool"
          setSelected={() => undefined}
          possibleValues={windowOptions}
        />
        <Select
          label="Managed"
          labelPosition="left"
          selected="School profile"
          setSelected={() => undefined}
          possibleValues={[`Parent setting`, `School profile`]}
          disabled
        />
      </StorySection>
      <StorySection
        title="With icons and descriptions"
        contentClassName="grid items-end gap-5 sm:grid-cols-2"
      >
        <StatefulSelect
          label="Child"
          selected="Franny"
          setSelected={() => undefined}
          possibleValues={[
            {
              value: `Sally`,
              label: `Sally`,
              description: `MacBook and iPhone`,
              icon: UserIcon,
            },
            { value: `Franny`, label: `Franny`, description: `iPad`, icon: UserIcon },
            {
              value: `Jimmy`,
              label: `Jimmy`,
              description: `No devices yet`,
              icon: UserIcon,
            },
          ]}
        />
        <StatefulSelect
          label="Policy"
          selected="homework"
          setSelected={() => undefined}
          possibleValues={[
            {
              value: `homework`,
              label: `Homework focus`,
              description: `Allow school and research sites.`,
              icon: ShieldCheckIcon,
            },
            {
              value: `bedtime`,
              label: `Bedtime`,
              description: `Block entertainment and games.`,
              icon: MoonIcon,
            },
          ]}
        />
      </StorySection>
    </StoryCanvas>
  ),
};
