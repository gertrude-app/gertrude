import { ArrowRightIcon, SearchIcon } from 'lucide-react';
import { fn } from 'storybook/test';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type { ComponentProps, FC } from 'react';
import Input from './Input';
import {
  StoryCanvas,
  StorySection,
  galleryParameters,
  useSyncedStoryState,
} from '#/storybook/StoryLayout';

const inputAction = fn();
const types = [`text`, `password`, `email`, `number`, `time`] as const;

type InputProps = ComponentProps<typeof Input>;

const StatefulInput: FC<InputProps> = ({ value, ...args }) => {
  const [currentValue, setCurrentValue] = useSyncedStoryState(value);

  return <Input {...args} value={currentValue} setValue={setCurrentValue} />;
};

const meta = {
  title: 'UI/Input',
  component: Input,
  args: { type: `text`, value: `school.edu`, setValue: () => undefined },
  argTypes: {
    type: { options: types, control: { type: `inline-radio` } },
    value: { control: `text` },
    label: { control: `text` },
    placeholder: { control: `text` },
    prefix: { control: `text` },
    suffix: { control: `text` },
    helperText: { control: `text` },
    error: { control: `text` },
    required: { control: `boolean` },
    disabled: { control: `boolean` },
    autoComplete: { control: false },
    button: { control: false },
    className: { control: false },
    id: { control: false },
    name: { control: false },
    setValue: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Input>;

export default meta;

type Story = StoryObj<typeof meta>;

export const TypeVariants: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection
        title="Input types"
        contentClassName="grid items-end gap-5 sm:grid-cols-2 lg:grid-cols-3"
      >
        <StatefulInput
          type="text"
          label="Text"
          value="Sally"
          setValue={() => undefined}
        />
        <StatefulInput
          type="email"
          label="Email"
          value="parent@example.com"
          setValue={() => undefined}
        />
        <StatefulInput
          type="password"
          label="Password"
          value="secret-password"
          setValue={() => undefined}
        />
        <StatefulInput
          type="number"
          label="Number"
          value="45"
          suffix="minutes"
          setValue={() => undefined}
        />
        <StatefulInput
          type="time"
          label="Time"
          value="20:00"
          setValue={() => undefined}
        />
      </StorySection>
    </StoryCanvas>
  ),
};

export const Adornments: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection
        title="Prefix and suffix"
        contentClassName="grid items-end gap-5 sm:grid-cols-2"
      >
        <StatefulInput
          type="text"
          label="Website"
          prefix="https://"
          value="khanacademy.org"
          setValue={() => undefined}
        />
        <StatefulInput
          type="number"
          label="Duration"
          suffix="minutes"
          value="30"
          setValue={() => undefined}
        />
        <StatefulInput
          type="text"
          label="Search action"
          value="math"
          setValue={() => undefined}
          button={{ label: `Search`, icon: SearchIcon, onClick: inputAction }}
        />
        <StatefulInput
          type="text"
          label="Suffix action"
          suffix="rules"
          value="12"
          setValue={() => undefined}
          button={{ label: `View`, icon: ArrowRightIcon, onClick: inputAction }}
        />
      </StorySection>
    </StoryCanvas>
  ),
};

export const HelpAndError: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection
        title="Support text"
        contentClassName="grid items-start gap-5 sm:grid-cols-2"
      >
        <StatefulInput
          type="text"
          label="Allowed website"
          value="school.edu"
          helperText="Enter a host without https:// or a path."
          setValue={() => undefined}
        />
        <StatefulInput
          type="text"
          label="Blocked website"
          value="https://bad.example/path"
          error="Use only the host, without https:// or a path."
          setValue={() => undefined}
        />
      </StorySection>
    </StoryCanvas>
  ),
};

export const Disabled: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-3xl">
      <StorySection
        title="Disabled fields"
        contentClassName="grid items-start gap-5 sm:grid-cols-2"
      >
        <Input
          type="text"
          label="Managed value"
          value="School profile"
          setValue={() => undefined}
          disabled
        />
        <Input
          type="text"
          label="Disabled action"
          value="gertrude.app"
          setValue={() => undefined}
          button={{ label: `Check`, icon: SearchIcon, onClick: inputAction }}
          disabled
        />
      </StorySection>
    </StoryCanvas>
  ),
};
