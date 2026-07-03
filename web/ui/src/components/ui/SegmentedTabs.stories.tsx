import type { Meta, StoryObj } from '@storybook/tanstack-react';
import SegmentedTabs from './SegmentedTabs';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const settingsTabs = [
  { label: `Overview`, segment: `` },
  { label: `Devices`, segment: `devices`, badgeCount: 4 },
  { label: `Notifications`, segment: `notifications` },
  { label: `Billing`, segment: `billing` },
] as const;

const peopleTabs = [
  { label: `Activity`, segment: `` },
  { label: `Mac settings`, segment: `mac-settings` },
  { label: `iOS settings`, segment: `ios-settings` },
  { label: `Requests`, segment: `requests`, badgeCount: 2 },
  { label: `Keychains`, segment: `keychains`, badgeCount: 6 },
  { label: `Devices`, segment: `devices`, badgeCount: 3 },
  { label: `Schedules`, segment: `schedules` },
] as const;

const meta = {
  title: 'UI/SegmentedTabs',
  component: SegmentedTabs,
  args: {
    basePath: `/`,
    tabs: [...settingsTabs],
  },
  argTypes: {
    basePath: { control: `text` },
    className: { control: false },
    tabs: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof SegmentedTabs>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-5xl">
      <StorySection title="Standard" contentClassName="w-full">
        <div className="w-full @container/main">
          <SegmentedTabs basePath="/" tabs={[...settingsTabs]} />
        </div>
      </StorySection>
      <StorySection title="Narrow overflow" contentClassName="w-full">
        <div className="w-80 @container/main">
          <SegmentedTabs basePath="/" tabs={[...peopleTabs]} />
        </div>
      </StorySection>
    </StoryCanvas>
  ),
};
