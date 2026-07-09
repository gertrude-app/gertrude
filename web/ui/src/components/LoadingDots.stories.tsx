import type { Meta, StoryObj } from '@storybook/tanstack-react';
import LoadingDots from './LoadingDots';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const sizes = [`xsmall`, `small`, `medium`, `large`] as const;
const meta = {
  title: 'UI/Components/LoadingDots',
  component: LoadingDots,
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof LoadingDots>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Sizes: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Default">
        {sizes.map((size) => (
          <div
            key={size}
            className="flex min-w-28 flex-col items-center gap-4 rounded-xl border border-stone-200 bg-white px-5 py-4 shadow-sm shadow-stone-300/30"
          >
            <span className="text-sm text-stone-500">{size}</span>
            <LoadingDots size={size} />
          </div>
        ))}
      </StorySection>
      <StorySection title="Inverted">
        {sizes.map((size) => (
          <div
            key={size}
            className="flex min-w-28 flex-col items-center gap-4 rounded-xl bg-violet-500 px-5 py-4 shadow-sm shadow-violet-500/30"
          >
            <span className="text-sm text-white/80">{size}</span>
            <LoadingDots size={size} variant="inverted" />
          </div>
        ))}
      </StorySection>
    </StoryCanvas>
  ),
};
