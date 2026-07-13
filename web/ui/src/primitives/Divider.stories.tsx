import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type React from 'react';
import Card from './Card';
import Divider from './Divider';
import HStack from './HStack';
import VStack from './VStack';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const meta = {
  title: 'UI/Primitives/Divider',
  component: Divider,
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof Divider>;

export default meta;

type Story = StoryObj<typeof meta>;

const DemoLabel: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <span className="text-sm font-medium text-stone-900">{children}</span>
);

const DemoCopy: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <span className="text-sm leading-5 text-stone-600">{children}</span>
);

export const Horizontal: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Horizontal" contentClassName="block w-full">
        <Card>
          <VStack gap={4}>
            <VStack gap={1}>
              <DemoLabel>Primary settings</DemoLabel>
              <DemoCopy>Parent layout controls the spacing around the line.</DemoCopy>
            </VStack>
            <Divider />
            <VStack gap={1}>
              <DemoLabel>Secondary settings</DemoLabel>
              <DemoCopy>The divider itself has no default margin.</DemoCopy>
            </VStack>
          </VStack>
        </Card>
      </StorySection>
    </StoryCanvas>
  ),
};

export const Vertical: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Vertical" contentClassName="block w-full">
        <Card>
          <HStack gap={4} align="stretch" className="min-h-24">
            <VStack gap={1} className="flex-1">
              <DemoLabel>Mac</DemoLabel>
              <DemoCopy>Screenshot, keylogging, and app rules.</DemoCopy>
            </VStack>
            <Divider orientation="vertical" />
            <VStack gap={1} className="flex-1">
              <DemoLabel>iPhone / iPad</DemoLabel>
              <DemoCopy>App locking and supervised-device settings.</DemoCopy>
            </VStack>
          </HStack>
        </Card>
      </StorySection>
    </StoryCanvas>
  ),
};
