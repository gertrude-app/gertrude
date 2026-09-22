import type { Meta, StoryObj } from '@storybook/tanstack-react';
import CountBadge from './CountBadge';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const meta = {
  title: 'UI/Components/Count Badge',
  component: CountBadge,
  args: { children: 2 },
  parameters: { layout: `fullscreen`, screenshotsAt: [`mobile`, `desktop`] },
} satisfies Meta<typeof CountBadge>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      {([`default`, `compact`] as const).flatMap((size) =>
        ([`dark`, `light`] as const).map((shade) => (
          <StorySection
            key={`${size}-${shade}`}
            title={`${size} · ${shade}`}
            contentClassName="rounded-xl bg-white p-4"
          >
            {[0, 1, 2, 12, 999, `99+`].map((count) => (
              <CountBadge key={count} size={size} shade={shade}>
                {count}
              </CountBadge>
            ))}
          </StorySection>
        )),
      )}
    </StoryCanvas>
  ),
};
