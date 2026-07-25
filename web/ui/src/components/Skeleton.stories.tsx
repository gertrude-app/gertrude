import type { SkeletonRadius } from './Skeleton';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Skeleton from './Skeleton';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const radii: SkeletonRadius[] = [`small`, `medium`, `large`, `full`];

const meta = {
  title: 'UI/Components/Skeleton',
  component: Skeleton,
  argTypes: {
    radius: { options: radii, control: { type: `inline-radio` } },
  },
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof Skeleton>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Radius">
        {radii.map((radius) => (
          <div
            key={radius}
            className="flex min-w-32 flex-col gap-3 rounded-xl border border-stone-200 bg-white p-4 shadow-sm shadow-stone-300/30"
          >
            <span className="text-xs text-stone-500">{radius}</span>
            <Skeleton radius={radius} className="h-10 w-24" />
          </div>
        ))}
      </StorySection>
      <StorySection title="Composed placeholder">
        <div className="flex w-full max-w-md flex-col gap-4 rounded-2xl border border-stone-200 bg-white p-5 shadow-sm shadow-stone-300/30">
          <div className="flex items-center gap-3">
            <Skeleton radius="full" className="size-12 shrink-0" />
            <div className="flex flex-1 flex-col gap-2">
              <Skeleton className="h-4 w-36" />
              <Skeleton className="h-3 w-24" />
            </div>
          </div>
          <Skeleton radius="large" className="h-24 w-full" />
          <div className="flex gap-2">
            <Skeleton className="h-9 w-20" />
            <Skeleton className="h-9 w-28" />
          </div>
        </div>
      </StorySection>
    </StoryCanvas>
  ),
};
