import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Card from './Card';
import Divider from './Divider';
import HStack from './HStack';
import VStack from './VStack';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const meta = {
  title: 'UI/Primitives/Card',
  component: Card,
  args: {
    children: `Card content`,
  },
  argTypes: {
    as: { control: false },
    children: { control: false },
    className: { control: false },
    padding: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Card>;

export default meta;

type Story = StoryObj<typeof meta>;

const MetricCard: React.FC<{
  title: string;
  value: string;
  helper: string;
}> = ({ title, value, helper }) => (
  <Card>
    <VStack gap={3}>
      <VStack gap={1}>
        <span className="text-sm font-medium text-stone-500">{title}</span>
        <span className="text-3xl font-medium text-stone-950">{value}</span>
      </VStack>
      <Divider />
      <span className="text-sm leading-5 text-stone-600">{helper}</span>
    </VStack>
  </Card>
);

export const Surfaces: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection
        title="Default surface"
        contentClassName="grid w-full grid-cols-1 gap-4 md:grid-cols-3"
      >
        <MetricCard
          title="People"
          value="3"
          helper="Protected children in this family."
        />
        <MetricCard
          title="Devices"
          value="7"
          helper="Macs and iOS devices reporting in."
        />
        <MetricCard
          title="Requests"
          value="12"
          helper="Unlock and suspension requests this week."
        />
      </StorySection>
    </StoryCanvas>
  ),
};

export const ResponsivePadding: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Responsive padding" contentClassName="block w-full">
        <Card padding={{ default: 3, sm: 5, lg: 8 }}>
          <VStack gap={{ default: 2, sm: 4 }}>
            <code className="w-fit rounded border border-stone-200 bg-stone-50 px-1.5 py-0.5 text-[11px] text-stone-600">
              padding={`{{ default: 3, sm: 5, lg: 8 }}`}
            </code>
            <h3 className="text-xl font-medium text-stone-950">Responsive card</h3>
            <p className="max-w-2xl text-sm leading-6 text-stone-600">
              The Card owns the surface styling while padding can adapt at breakpoints.
              Parent layout still owns external spacing.
            </p>
          </VStack>
        </Card>
      </StorySection>
    </StoryCanvas>
  ),
};

export const SemanticElements: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Semantic element" contentClassName="block w-full">
        <Card as="section" aria-labelledby="card-section-title">
          <VStack gap={4}>
            <HStack justify="between" gap={3}>
              <h3 id="card-section-title" className="text-lg font-medium text-stone-950">
                Rendered as a section
              </h3>
              <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-800">
                Active
              </span>
            </HStack>
            <Divider />
            <p className="text-sm leading-6 text-stone-600">
              Card accepts common semantic elements and standard HTML attributes.
            </p>
          </VStack>
        </Card>
      </StorySection>
    </StoryCanvas>
  ),
};
