import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Banner from './Banner';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const variants = [`neutral`, `warning`, `error`] as const;

const copy: Record<(typeof variants)[number], string> = {
  neutral: `Profile changes may take a few minutes to appear on the child’s device.`,
  warning: `Open Gertrude on the child’s device and choose Info → Sync Profile after changing settings.`,
  error: `This profile could not be synced. Check the device connection and try again.`,
};

const meta = {
  title: 'UI/Components/Banner',
  component: Banner,
  args: { children: copy.neutral },
  argTypes: {
    children: { control: `text` },
    variant: { options: variants, control: { type: `inline-radio` } },
    className: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Banner>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Variants: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-3xl">
      <StorySection title="Variants" contentClassName="flex-col items-stretch">
        {variants.map((variant) => (
          <Banner key={variant} variant={variant}>
            {copy[variant]}
          </Banner>
        ))}
      </StorySection>
      <StorySection title="Rich content" contentClassName="flex-col items-stretch">
        <Banner variant="warning">
          After changing settings, open Gertrude on the child’s device and choose{` `}
          <strong>Info → Sync Profile</strong>.
        </Banner>
      </StorySection>
    </StoryCanvas>
  ),
};
