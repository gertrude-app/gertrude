import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Card, { type CardPreset } from './Card';
import Divider from './Divider';
import HStack from './HStack';
import Text from './Text';
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
    preset: { control: false },
  },
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof Card>;

export default meta;

type Story = StoryObj<typeof meta>;

const MetricCard: React.FC<{
  title: string;
  value: string;
  helper: string;
  preset?: CardPreset;
}> = ({ title, value, helper, preset }) => (
  <Card preset={preset}>
    <VStack gap={3}>
      <VStack gap={1}>
        <Text variant="label">{title}</Text>
        <Text variant="display">{value}</Text>
      </VStack>
      <Divider />
      <Text variant="bodySubtle">{helper}</Text>
    </VStack>
  </Card>
);

export const Surfaces: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection
        title="Big preset"
        contentClassName="grid w-full grid-cols-1 gap-4 md:grid-cols-3"
      >
        <MetricCard
          preset="big"
          title="People"
          value="3"
          helper="Protected children in this family."
        />
        <MetricCard
          preset="big"
          title="Devices"
          value="7"
          helper="Macs and iOS devices reporting in."
        />
        <MetricCard
          preset="big"
          title="Requests"
          value="12"
          helper="Unlock and suspension requests this week."
        />
      </StorySection>
      <StorySection
        title="Compact preset"
        contentClassName="grid w-full grid-cols-1 gap-3 md:grid-cols-3"
      >
        <MetricCard
          preset="compact"
          title="People"
          value="3"
          helper="Protected children in this family."
        />
        <MetricCard
          preset="compact"
          title="Devices"
          value="7"
          helper="Macs and iOS devices reporting in."
        />
        <MetricCard
          preset="compact"
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
            <Text as="h3" variant="title">
              Responsive card
            </Text>
            <Text as="p" variant="proseSubtle" className="max-w-2xl">
              The Card owns the surface styling while padding can adapt at breakpoints.
              Parent layout still owns external spacing.
            </Text>
          </VStack>
        </Card>
      </StorySection>
    </StoryCanvas>
  ),
};

export const Sections: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection
        title="Body and footer"
        contentClassName="grid w-full grid-cols-1 gap-4 md:grid-cols-2"
      >
        <Card padding={0} className="overflow-hidden">
          <Card.Body padding={4}>
            <Text as="h3" variant="bodyLargeStrong">
              Email parent@example.com for unlock requests
            </Text>
          </Card.Body>
          <Card.Footer>
            <HStack justify="between" gap={3}>
              <Text variant="captionMuted">Email</Text>
              <HStack gap={2}>
                <button className="rounded-md border border-stone-300 bg-white px-2 py-1 text-xs text-stone-800">
                  Edit
                </button>
                <button className="rounded-md border border-red-200 bg-red-50 px-2 py-1 text-xs text-red-900">
                  Delete
                </button>
              </HStack>
            </HStack>
          </Card.Footer>
        </Card>
        <Card padding={0}>
          <Card.Body padding={{ default: 3, md: 5 }}>
            <VStack gap={2}>
              <Text as="h3" variant="heading">
                Responsive body padding
              </Text>
              <Text as="p" variant="bodySubtle">
                Body padding uses the same spacing scale as Card padding.
              </Text>
            </VStack>
          </Card.Body>
          <Card.Footer>
            <Text variant="captionMuted">
              Footer owns the divider and default padding.
            </Text>
          </Card.Footer>
        </Card>
      </StorySection>
    </StoryCanvas>
  ),
};

export const InteractiveStates: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection
        title="Interactive state"
        contentClassName="grid w-full grid-cols-1 gap-3 md:grid-cols-3"
      >
        <Card as="button" type="button" interactive className="text-left">
          <Text variant="bodyStrong">Default interactive</Text>
          <Text variant="bodyMuted">Hover and focus are owned by Card.</Text>
        </Card>
        <Card as="button" type="button" interactive selected className="text-left">
          <Text variant="bodyStrong">Selected interactive</Text>
          <Text variant="bodyMuted">Selected cards use the violet surface.</Text>
        </Card>
        <Card as="button" type="button" interactive disabled className="text-left">
          <Text variant="bodyStrong">Disabled interactive</Text>
          <Text variant="bodyMuted">Disabled cards are muted and non-interactive.</Text>
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
              <Text as="h3" id="card-section-title" variant="heading">
                Rendered as a section
              </Text>
              <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-800">
                Active
              </span>
            </HStack>
            <Divider />
            <Text as="p" variant="proseSubtle">
              Card accepts common semantic elements and standard HTML attributes.
            </Text>
          </VStack>
        </Card>
      </StorySection>
    </StoryCanvas>
  ),
};
