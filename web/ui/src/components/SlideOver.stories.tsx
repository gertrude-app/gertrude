import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Button from './Button';
import Input from './Input';
import SlideOver from './SlideOver';
import Toggle from './Toggle';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const sizes = [`small`, `medium`, `large`] as const;

const SlideOverBody: React.FC = () => {
  const [site, setSite] = React.useState(`khanacademy.org`);
  const [enabled, setEnabled] = React.useState(true);

  return (
    <div className="flex h-full flex-col gap-5 py-6">
      <p className="text-sm leading-6 text-stone-600">
        Put any custom content inside the slide over. This area often holds edit forms,
        review panels, or account details.
      </p>
      <Input
        type="text"
        label="Allowed website"
        prefix="https://"
        value={site}
        setValue={setSite}
      />
      <div className="flex items-center justify-between rounded-xl border border-stone-200 bg-white p-4">
        <div>
          <div className="text-sm font-medium text-stone-900">Enabled</div>
          <div className="text-xs leading-5 text-stone-500">Apply this rule now.</div>
        </div>
        <Toggle checked={enabled} setChecked={setEnabled} />
      </div>
    </div>
  );
};

const meta = {
  title: 'UI/Components/SlideOver',
  component: SlideOver,
  args: {
    heading: `Edit allowed site`,
    subheading: `Changes apply the next time the child’s device syncs.`,
    ariaLabel: `Edit allowed site`,
    children: <SlideOverBody />,
  },
  argTypes: {
    heading: { control: `text` },
    subheading: { control: `text` },
    size: { options: sizes, control: { type: `inline-radio` } },
    dismissible: { control: `boolean` },
    withPx: { control: `boolean` },
    ariaLabel: { control: false },
    children: { control: false },
    className: { control: false },
    closeTo: { control: false },
    defaultOpen: { control: false },
    onOpenChange: { control: false },
    open: { control: false },
    overlayClassName: { control: false },
    path: { control: false },
    trigger: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof SlideOver>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Sizes: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Sizes">
        {sizes.map((size) => (
          <SlideOverTrigger
            key={size}
            size={size}
            heading={`${size} slide over`}
            withPx
          />
        ))}
      </StorySection>
    </StoryCanvas>
  ),
};

export const HeadingOptions: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Heading treatment">
        <SlideOverTrigger size="medium" heading="With heading" withPx />
        <SlideOverTrigger
          size="medium"
          heading="With subheading"
          subheading="Use subheadings to explain secondary context."
          withPx
        />
        <SlideOverTrigger size="medium" ariaLabel="Unheaded slide over" withPx />
      </StorySection>
    </StoryCanvas>
  ),
};

type SlideOverTriggerProps = Omit<React.ComponentProps<typeof SlideOver>, `children`>;

const SlideOverTrigger: React.FC<SlideOverTriggerProps> = (props) => {
  const [open, setOpen] = React.useState(false);

  return (
    <>
      <Button type="button" onClick={() => setOpen(true)}>
        Open {props.size ?? `medium`}
      </Button>
      <SlideOver {...props} open={open} onOpenChange={setOpen}>
        <SlideOverBody />
      </SlideOver>
    </>
  );
};
