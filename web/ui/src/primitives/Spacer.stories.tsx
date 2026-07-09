import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import HStack from './HStack';
import Spacer from './Spacer';
import VStack from './VStack';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const meta = {
  title: 'UI/Primitives/Spacer',
  component: Spacer,
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof Spacer>;

export default meta;

type Story = StoryObj<typeof meta>;

const DemoFrame: React.FC<{
  title: string;
  children: React.ReactNode;
  className?: string;
}> = ({ title, children, className }) => (
  <div className="rounded-2xl border border-stone-200 bg-white p-3 shadow shadow-stone-300/30">
    <div className="mb-3">
      <code className="rounded border border-stone-200 bg-stone-50 px-1.5 py-0.5 text-[11px] text-stone-600">
        {title}
      </code>
    </div>
    <div
      className={`rounded-xl border border-dashed border-stone-300 bg-stone-50 p-3 ${className ?? ``}`}
    >
      {children}
    </div>
  </div>
);

const DemoItem: React.FC<{ label: string; className?: string }> = ({
  label,
  className,
}) => (
  <div
    className={`rounded-lg border border-stone-200 bg-white px-3 py-2 text-sm font-medium text-stone-800 shadow shadow-stone-300/30 ${className ?? ``}`}
  >
    {label}
  </div>
);

export const HorizontalFill: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Horizontal fill" contentClassName="block w-full">
        <DemoFrame title="HStack + Spacer" className="w-full">
          <HStack gap={3} className="w-full">
            <DemoItem label="Leading" />
            <Spacer className="h-2 rounded-full bg-violet-300/70" />
            <DemoItem label="Trailing" />
          </HStack>
        </DemoFrame>
      </StorySection>
    </StoryCanvas>
  ),
};

export const VerticalFill: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Vertical fill" contentClassName="block w-full">
        <DemoFrame title="VStack + Spacer" className="h-64">
          <VStack gap={3} className="h-full">
            <DemoItem label="Header" />
            <Spacer className="rounded-xl border border-violet-200 bg-violet-100/80" />
            <DemoItem label="Footer" />
          </VStack>
        </DemoFrame>
      </StorySection>
    </StoryCanvas>
  ),
};

export const MultipleSpacers: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Multiple spacers" contentClassName="block w-full">
        <DemoFrame title="equal remaining space" className="w-full">
          <HStack gap={3} className="w-full">
            <DemoItem label="A" />
            <Spacer className="h-2 rounded-full bg-violet-300/70" />
            <DemoItem label="B" />
            <Spacer className="h-2 rounded-full bg-violet-300/70" />
            <DemoItem label="C" />
          </HStack>
        </DemoFrame>
      </StorySection>
    </StoryCanvas>
  ),
};
