import type { Meta, StoryObj } from '@storybook/tanstack-react';
import AppIcon from './AppIcon';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const sizes = [`small`, `medium`, `large`] as const;

const meta = {
  title: 'UI/Components/App Icon',
  component: AppIcon,
  args: { src: `/gertrude-app-icons/blocker.webp` },
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof AppIcon>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Sizes">
        {sizes.map((size) => (
          <AppIcon key={size} src="/gertrude-app-icons/blocker.webp" size={size} />
        ))}
      </StorySection>
      <StorySection title="App artwork">
        <AppIcon src="/gertrude-app-icons/music.webp" size="large" />
        <AppIcon src="/gertrude-app-icons/podcasts.webp" size="large" />
      </StorySection>
    </StoryCanvas>
  ),
};
