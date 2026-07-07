import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Stack from './Stack';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const meta = {
  title: 'UI/Primitives/Stack',
  component: Stack,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Stack>;

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

export const Directions: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection
        title="Direction"
        contentClassName="grid w-full grid-cols-1 gap-4 md:grid-cols-2"
      >
        <DemoFrame title={'direction="vertical"'}>
          <Stack direction="vertical" gap={2}>
            <DemoItem label="First" />
            <DemoItem label="Second" />
            <DemoItem label="Third" />
          </Stack>
        </DemoFrame>
        <DemoFrame title={'direction="horizontal"'}>
          <Stack direction="horizontal" gap={2}>
            <DemoItem label="First" />
            <DemoItem label="Second" />
            <DemoItem label="Third" />
          </Stack>
        </DemoFrame>
      </StorySection>
    </StoryCanvas>
  ),
};

export const ContainerResponsive: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl gap-12">
      <StorySection title="Container responsive props" contentClassName="block w-full">
        <DemoFrame
          title={'direction={{ default: "vertical", "@xl/main": "horizontal" }}'}
        >
          <Stack
            direction={{ default: `vertical`, '@xl/main': `horizontal` }}
            gap={{ default: 2, '@xl/main': 4 }}
            align={{ default: `stretch`, '@xl/main': `center` }}
            justify={{ default: `start`, '@xl/main': `between` }}
          >
            <DemoItem label="Profile" />
            <DemoItem label="Devices" />
            <DemoItem label="Activity" />
          </Stack>
        </DemoFrame>
      </StorySection>
    </StoryCanvas>
  ),
};

export const ResponsiveWrapping: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Responsive wrap" contentClassName="block w-full">
        <DemoFrame title={'wrap={{ default: true, "@xl/main": false }}'}>
          <Stack
            direction="horizontal"
            gap={2}
            wrap={{ default: true, '@xl/main': false }}
          >
            {[
              `email@example.com`,
              `dashboard login`,
              `suspension request`,
              `macOS`,
              `screenshots`,
              `keylogging`,
            ].map((label) => (
              <DemoItem key={label} label={label} />
            ))}
          </Stack>
        </DemoFrame>
      </StorySection>
    </StoryCanvas>
  ),
};

export const ResponsiveVisibility: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection
        title="Responsive visibility"
        contentClassName="grid w-full grid-cols-1 gap-4 md:grid-cols-2"
      >
        <DemoFrame title={'hideBelow="@xl/main"'}>
          <Stack hideBelow="@xl/main" gap={2}>
            <DemoItem label="Shown at @xl/main and wider" />
            <DemoItem label="Hidden below that container size" />
          </Stack>
        </DemoFrame>
        <DemoFrame title={'hideAbove="@xl/main"'}>
          <Stack hideAbove="@xl/main" gap={2}>
            <DemoItem label="Shown below @xl/main" />
            <DemoItem label="Hidden at that container size and wider" />
          </Stack>
        </DemoFrame>
      </StorySection>
    </StoryCanvas>
  ),
};
