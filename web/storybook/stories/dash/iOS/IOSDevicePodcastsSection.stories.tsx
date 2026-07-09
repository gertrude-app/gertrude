import {
  AppHeader,
  BlockGroupList,
  PageHeading,
  PodcastsDeviceSection,
  ResetPinModal,
  ToggleCard,
} from '@dash/components';
import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import React, { useState } from 'react';
import type { PodcastsStatus } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';

const mockRequestPinCode = async (): Promise<number> => {
  await new Promise((resolve) => setTimeout(resolve, 600));
  return 481920;
};

const MOCK_GROUPS = [
  {
    id: `1`,
    name: `Ads`,
    description: `Block the most common ad providers across all apps.`,
    longDescription: `Blocks the 20 most common ad providers, including Google ads, in all browsers and apps.`,
  },
  {
    id: `2`,
    name: `GIFs`,
    description: `Block GIFs in Messages #images, WhatsApp, Signal, and more.`,
    longDescription: `Blocks viewing and searching for GIFs in the #images feature of Apple's texting app.`,
  },
  {
    id: `3`,
    name: `Spotlight`,
    description: `Block internet searches through Spotlight.`,
    longDescription: `The built in search bar in iOS (called Spotlight) allows searching for information and images from the internet.`,
  },
];

const BlockerSection: React.FC<{ deviceType: string }> = ({ deviceType: dt }) => {
  const [enabled, setEnabled] = useState<string[]>([`1`, `3`]);
  const [profileLocked, setProfileLocked] = useState(true);
  const [allowAppRemoval, setAllowAppRemoval] = useState(false);
  const [allowEraseContentAndSettings, setAllowEraseContentAndSettings] = useState(false);
  const [allowAppInstallation, setAllowAppInstallation] = useState(true);
  return (
    <div className="max-w-3xl">
      <AppHeader app="blocker" />
      <div className="mt-6">
        <BlockGroupList
          groups={MOCK_GROUPS}
          enabledGroupIds={enabled}
          onToggle={(id) =>
            setEnabled((prev) =>
              prev.includes(id) ? prev.filter((g) => g !== id) : [...prev, id],
            )
          }
        />
      </div>
      <div className="mt-12">
        <h2 className="text-lg font-bold text-slate-700">Supervision Profile Settings</h2>
        <div className="mt-2 mb-4 flex items-start gap-3 rounded-xl bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-800">
          <i className="fa-solid fa-circle-info text-amber-500 mt-0.5 shrink-0" />
          <span>
            After changing any setting below, you&rsquo;ll need to sync the profile on the
            {` `}
            {dt} by opening the Gertrude app and going to{` `}
            <b>Info &rarr; Sync Profile</b>.
          </span>
        </div>
        <ToggleCard
          title="Prevent protection removal"
          description={`Make it impossible for the ${dt} user to remove Gertrude’s protection.`}
          enabled={profileLocked}
          setEnabled={setProfileLocked}
          warning={
            !profileLocked
              ? `The ${dt} user may remove the profile in order to stop Gertrude’s protection and uninstall.`
              : undefined
          }
        />
        <ToggleCard
          title="Allow deleting apps"
          description={`Keeping this off prevents the ${dt} user from deleting the Gertrude app, but also prevents them from deleting any app.`}
          enabled={allowAppRemoval}
          setEnabled={setAllowAppRemoval}
          warning={
            allowAppRemoval
              ? `The user can delete apps (including Gertrude) from their ${dt}`
              : undefined
          }
        />
        <ToggleCard
          title="Allow factory reset"
          description={`Allow the ${dt} to be erased and reset to factory settings, bypassing protection.`}
          enabled={allowEraseContentAndSettings}
          setEnabled={setAllowEraseContentAndSettings}
          warning={
            allowEraseContentAndSettings
              ? `The user will be able to erase the ${dt} removing Gertrude and all restrictions`
              : undefined
          }
        />
        <ToggleCard
          title="Allow installing apps"
          description={`Allow the ${dt} user to install new apps from the App Store. Turn this off to remove the App Store icon entirely and block app installation.`}
          enabled={allowAppInstallation}
          setEnabled={setAllowAppInstallation}
        />
      </div>
      <div className="flex justify-end border-slate-200 pt-8 border-t-2 mt-12">
        <Button type="button" disabled color="primary" onClick={() => {}}>
          Save settings
        </Button>
      </div>
    </div>
  );
};

const IOSDevicePageWithPodcasts: React.FC<{
  childName: string;
  modelName: string;
  hasBlocker: boolean;
  podcastsStatus: PodcastsStatus;
  accessEndsAt?: string;
  trialDaysRemaining?: number;
}> = ({
  childName,
  modelName,
  hasBlocker,
  podcastsStatus,
  accessEndsAt,
  trialDaysRemaining,
}) => {
  const dt = modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;
  return (
    <div className="relative max-w-3xl">
      <PageHeading icon="phone">
        {posessive(childName)} {dt}
      </PageHeading>
      <div className="mt-8 space-y-16">
        <PodcastsDeviceSection
          status={podcastsStatus}
          childName={childName}
          deviceType={dt}
          accessEndsAt={accessEndsAt}
          trialDaysRemaining={trialDaysRemaining}
          requestPinCode={mockRequestPinCode}
        />
        {hasBlocker && <BlockerSection deviceType={dt} />}
      </div>
    </div>
  );
};

const meta = {
  title: 'Dashboard/iOS/IOSDevice Podcasts Section',
  component: IOSDevicePageWithPodcasts,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
  argTypes: {
    podcastsStatus: {
      control: `select`,
      options: [`active`, `approaching`, `paused`],
      description: `Podcasts subscription runway tier (flip to see all status-line variants)`,
    },
    accessEndsAt: { control: `text` },
    trialDaysRemaining: { control: `number` },
    hasBlocker: { control: false },
  },
} satisfies Meta<typeof IOSDevicePageWithPodcasts>;

type Story = StoryObj<typeof meta>;

export const PodcastsOnly: Story = {
  args: {
    childName: `Emma`,
    modelName: `iPhone 14 Pro`,
    hasBlocker: false,
    podcastsStatus: `active`,
    trialDaysRemaining: 24,
    accessEndsAt: `June 27, 2026`,
  },
};

export const BlockerAndPodcasts: Story = {
  args: {
    childName: `Luke`,
    modelName: `iPhone 14 Pro`,
    hasBlocker: true,
    podcastsStatus: `approaching`,
    accessEndsAt: `June 27, 2026`,
  },
};

const ResetPinModalPreview: React.FC = () => {
  const [open, setOpen] = useState(true);
  return (
    <div className="p-10">
      <Button type="button" color="secondary" onClick={() => setOpen(true)}>
        Open Reset PIN modal
      </Button>
      <ResetPinModal
        isOpen={open}
        onClose={() => setOpen(false)}
        childName="Emma"
        deviceType="iPhone"
        code={481920}
      />
    </div>
  );
};

export const ResetPin: Story = {
  args: {
    childName: `Emma`,
    modelName: `iPhone 14 Pro`,
    hasBlocker: false,
    podcastsStatus: `active`,
  },
  render: () => <ResetPinModalPreview />,
};

export default meta;
