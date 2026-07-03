import { PlusIcon, SaveIcon, SettingsIcon } from 'lucide-react';
import { fn } from 'storybook/test';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import PageHeading from './PageHeading';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const headingAction = fn();

const meta = {
  title: 'UI/PageHeading',
  component: PageHeading,
  args: {
    title: `Family settings`,
    subtitle: `For the whole family`,
    breadcrumbs: [{ text: `Settings`, href: `/settings` }],
    buttons: [
      { text: `Cancel`, onClick: headingAction },
      {
        text: `Save changes`,
        variant: `primary`,
        icon: SaveIcon,
        onClick: headingAction,
      },
    ],
  },
  argTypes: {
    title: { control: `text` },
    subtitle: { control: `text` },
    breadcrumbs: { control: false },
    buttons: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof PageHeading>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-5xl">
      <StorySection title="Heading shapes" contentClassName="block w-full">
        <div className="flex w-full flex-col gap-10 rounded-2xl border border-stone-200 bg-white p-6 shadow-sm shadow-stone-300/30 @container/main">
          <PageHeading title="Dashboard" />
          <PageHeading
            title="Sally’s iPhone"
            breadcrumbs={[
              { text: `Devices`, href: `/devices` },
              { text: `Mobile devices`, href: `/devices/mobile` },
            ]}
          />
          <PageHeading
            title="Family settings"
            subtitle="For the whole family"
            breadcrumbs={[{ text: `Settings`, href: `/settings` }]}
            buttons={[
              { text: `Cancel`, onClick: headingAction },
              {
                text: `Save changes`,
                variant: `primary`,
                icon: SaveIcon,
                onClick: headingAction,
              },
            ]}
          />
          <PageHeading
            title="Keychains"
            subtitle="Trusted sites and apps"
            buttons={[
              { text: `Preferences`, href: `/settings/keychains`, icon: SettingsIcon },
              {
                text: `Add keychain`,
                variant: `primary`,
                icon: PlusIcon,
                onClick: headingAction,
              },
            ]}
          />
        </div>
      </StorySection>
    </StoryCanvas>
  ),
};
