import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type { ComponentProps, FC } from 'react';
import Textarea from './Textarea';
import {
  StoryCanvas,
  StorySection,
  galleryParameters,
  useSyncedStoryState,
} from '#/storybook/StoryLayout';

const resizeOptions = [`none`, `vertical`, `horizontal`, `both`] as const;

type TextareaProps = ComponentProps<typeof Textarea>;

const StatefulTextarea: FC<TextareaProps> = ({ value, ...args }) => {
  const [currentValue, setCurrentValue] = useSyncedStoryState(value);

  return <Textarea {...args} value={currentValue} setValue={setCurrentValue} />;
};

const meta = {
  title: 'UI/Components/Textarea',
  component: Textarea,
  args: {
    value: `Sally can use research sites until the science project is done.`,
    setValue: () => undefined,
  },
  argTypes: {
    value: { control: `text` },
    label: { control: `text` },
    placeholder: { control: `text` },
    rows: { control: { type: `number`, min: 2, max: 10, step: 1 } },
    helperText: { control: `text` },
    error: { control: `text` },
    disabled: { control: `boolean` },
    resize: { options: resizeOptions, control: { type: `inline-radio` } },
    id: { control: false },
    name: { control: false },
    required: { control: false },
    setValue: { control: false },
  },
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof Textarea>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection
        title="Common text areas"
        contentClassName="grid items-start gap-5 sm:grid-cols-2"
      >
        <StatefulTextarea
          label="Parent note"
          value="Sally can use research sites until the science project is done."
          rows={4}
          setValue={() => undefined}
        />
        <StatefulTextarea
          label="Unlock reason"
          value=""
          placeholder="Why should this site be allowed?"
          helperText="Visible to parents on this account."
          rows={4}
          setValue={() => undefined}
        />
        <Textarea
          label="Missing explanation"
          value=""
          setValue={() => undefined}
          error="Add a reason before approving this request."
          rows={3}
          resize="none"
        />
        <Textarea
          label="Managed note"
          value="This setting is managed by the school profile."
          setValue={() => undefined}
          disabled
          rows={3}
        />
      </StorySection>
    </StoryCanvas>
  ),
};
