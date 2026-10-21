import type { Meta, StoryObj } from '@storybook/tanstack-react';
import SelectionCircle from './SelectionCircle';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const meta = {
  title: 'UI/Primitives/Selection Circle',
  component: SelectionCircle,
  args: { selected: false },
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof SelectionCircle>;

export default meta;

type Story = StoryObj<typeof meta>;

export const States: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Selection states">
        <SelectionCircle selected={false} />
        <SelectionCircle selected />
      </StorySection>
    </StoryCanvas>
  ),
};
