import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import HStack from './HStack';
import { type StackAlign, type StackGap, type StackJustify } from './stack-utils';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const gaps = [0, 1, 2, 3, 4, 6, 8] satisfies StackGap[];
const aligns = [`start`, `center`, `end`, `stretch`, `baseline`] satisfies StackAlign[];
const justifies = [
  `start`,
  `center`,
  `end`,
  `between`,
  `around`,
] satisfies StackJustify[];

const meta = {
  title: 'UI/Primitives/HStack',
  component: HStack,
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof HStack>;

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

const CompactDemoItem: React.FC<{ label: string }> = ({ label }) => (
  <DemoItem
    label={label}
    className="flex h-9 w-9 items-center justify-center px-0 py-0"
  />
);

export const Spacing: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection
        title="Gap scale"
        contentClassName="grid w-full grid-cols-1 items-start gap-4 sm:grid-cols-2 lg:grid-cols-4"
      >
        {gaps.map((gap) => (
          <DemoFrame key={gap} title={`gap={${gap}}`}>
            <HStack gap={gap}>
              <CompactDemoItem label="A" />
              <CompactDemoItem label="B" />
              <CompactDemoItem label="C" />
            </HStack>
          </DemoFrame>
        ))}
      </StorySection>
    </StoryCanvas>
  ),
};

export const ResponsiveSpacing: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Responsive gap" contentClassName="block w-full">
        <DemoFrame title={'gap={{ default: 1, sm: 3, lg: 6 }}'}>
          <HStack gap={{ default: 1, sm: 3, lg: 6 }}>
            <CompactDemoItem label="A" />
            <CompactDemoItem label="B" />
            <CompactDemoItem label="C" />
          </HStack>
        </DemoFrame>
      </StorySection>
    </StoryCanvas>
  ),
};

export const Alignment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection
        title="Cross-axis alignment"
        contentClassName="grid w-full grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
      >
        {aligns.map((align) => (
          <DemoFrame key={align} title={`align="${align}"`} className="h-32">
            <HStack gap={2} align={align} className="h-full">
              <DemoItem label="Short" />
              <DemoItem label="Tall" className="py-8" />
              <DemoItem label="Medium" className="py-4" />
            </HStack>
          </DemoFrame>
        ))}
      </StorySection>
    </StoryCanvas>
  ),
};

export const Justification: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection
        title="Main-axis justification"
        contentClassName="grid w-full grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
      >
        {justifies.map((justify) => (
          <DemoFrame key={justify} title={`justify="${justify}"`}>
            <HStack gap={2} justify={justify} className="w-full">
              <DemoItem label="First" />
              <DemoItem label="Second" />
            </HStack>
          </DemoFrame>
        ))}
      </StorySection>
    </StoryCanvas>
  ),
};

export const Wrapping: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Wrapping" contentClassName="block w-full">
        <DemoFrame title="wrap" className="max-w-md">
          <HStack gap={2} wrap>
            {[
              `email@example.com`,
              `dashboard login`,
              `suspension request`,
              `macOS`,
              `screenshots`,
              `keylogging`,
              `Gertrude Music`,
            ].map((label) => (
              <DemoItem key={label} label={label} />
            ))}
          </HStack>
        </DemoFrame>
      </StorySection>
    </StoryCanvas>
  ),
};

export const SemanticElements: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Semantic element" contentClassName="block w-full">
        <DemoFrame title={'as="ul"'}>
          <HStack as="ul" gap={2} wrap className="m-0 list-none">
            <li>
              <DemoItem label="Rendered as a ul" />
            </li>
            <li>
              <DemoItem label="Keeps standard HTML attributes" />
            </li>
            <li>
              <DemoItem label="Still accepts className overrides" />
            </li>
          </HStack>
        </DemoFrame>
      </StorySection>
    </StoryCanvas>
  ),
};
