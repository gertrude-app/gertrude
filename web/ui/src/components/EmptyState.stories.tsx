import {
  BellOffIcon,
  KeyRoundIcon,
  MonitorSmartphoneIcon,
  PlusIcon,
  ShieldCheckIcon,
} from 'lucide-react';
import { fn } from 'storybook/test';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import EmptyState from './EmptyState';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const emptyStateAction = fn();

const meta = {
  title: 'UI/Components/EmptyState',
  component: EmptyState,
  args: {
    icon: ShieldCheckIcon,
    title: `No rules yet`,
    description: `Create a rule to start protecting this child’s device.`,
    button: {
      type: `button`,
      text: `Add rule`,
      icon: PlusIcon,
      variant: `primary`,
      onClick: emptyStateAction,
    },
  },
  argTypes: {
    title: { control: `text` },
    description: { control: `text` },
    button: { control: false },
    className: { control: false },
    icon: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof EmptyState>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection
        title="Empty states"
        contentClassName="grid items-stretch gap-5 md:grid-cols-2"
      >
        <EmptyState
          icon={ShieldCheckIcon}
          title="No rules yet"
          description="Create a rule to start protecting this child’s device."
          button={{
            type: `button`,
            text: `Add rule`,
            icon: PlusIcon,
            variant: `primary`,
            onClick: emptyStateAction,
          }}
        />
        <EmptyState
          icon={MonitorSmartphoneIcon}
          title="No devices"
          description="Install Gertrude on a Mac or supervised iOS device."
          button={{
            type: `link`,
            text: `Setup guide`,
            icon: PlusIcon,
            href: `https://gertrude.app/docs`,
          }}
        />
        <EmptyState
          icon={KeyRoundIcon}
          title="No keychains"
          description="Add a keychain before assigning trusted sites."
        />
        <EmptyState
          icon={BellOffIcon}
          title="No notifications"
          description="There is nothing new to review right now."
          button={{
            type: `button`,
            text: `Refresh`,
            variant: `ghost`,
            onClick: emptyStateAction,
          }}
        />
      </StorySection>
    </StoryCanvas>
  ),
};
