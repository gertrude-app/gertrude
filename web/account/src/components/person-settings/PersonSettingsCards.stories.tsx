import {
  StoryCanvas,
  StorySection,
  galleryParameters,
} from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import AddAllowedAlbumsSlideOver from './AddAllowedAlbumsSlideOver';
import AddBlockedDomainModal from './AddBlockedDomainModal';
import AddKeychainSlideOver from './AddKeychainSlideOver';
import AddMacAppSlideOver from './AddMacAppSlideOver';
import AllowedAlbumCard from './AllowedAlbumCard';
import ConfiguredAppRow from './ConfiguredAppRow';
import KeychainCard from './KeychainCard';
import ScheduleButton from './ScheduleButton';
import {
  albums,
  installedMacApps,
  keychains,
  weekdaySchedule,
} from '#/components/storybook/fixtures';

const noop = (): void => {};

const meta = {
  title: 'Account/Components/Person Settings/Cards and Pickers',
  parameters: { layout: 'fullscreen' },
};

export default meta;

const ScheduledKeychainCard: React.FC = () => {
  const [schedule, setSchedule] = React.useState<typeof weekdaySchedule | undefined>(
    weekdaySchedule,
  );

  return (
    <KeychainCard
      name={keychains[0]!.name}
      description={keychains[0]!.description}
      numKeys={keychains[0]!.numKeys}
      isPublic={keychains[0]!.isPublic}
      schedule={schedule}
      setSchedule={setSchedule}
      onRemove={noop}
      onEdit={noop}
    />
  );
};

export const Cards = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-5xl">
      <StorySection
        title="Keychains"
        contentClassName="grid grid-cols-1 gap-3 @3xl/main:grid-cols-2"
      >
        <ScheduledKeychainCard />
        <KeychainCard
          name={keychains[2]!.name}
          description={keychains[2]!.description}
          numKeys={keychains[2]!.numKeys}
          isPublic={keychains[2]!.isPublic}
          setSchedule={noop}
          onRemove={noop}
        />
      </StorySection>
      <StorySection
        title="Albums"
        contentClassName="grid grid-cols-2 gap-4 @3xl/main:grid-cols-4"
      >
        <AllowedAlbumCard album={albums[0]!} onToggleAlbumArt={noop} onRemove={noop} />
        <AllowedAlbumCard album={albums[2]!} onToggleAlbumArt={noop} onRemove={noop} />
        <AllowedAlbumCard album={albums[1]!} selected onSelect={noop} forceShowArtwork />
        <AllowedAlbumCard
          album={albums[3]!}
          disabled
          disabledLabel="Already added"
          onSelect={noop}
          forceShowArtwork
        />
      </StorySection>
      <StorySection title="Configured apps" contentClassName="flex-col items-stretch">
        <ConfiguredAppRow
          app={{
            nameOrBundleId: `Minecraft`,
            appIconUrl: `/example-app-icons/minecraft.webp`,
            schedule: weekdaySchedule,
          }}
          setSchedule={noop}
          onRemove={noop}
        />
        <ConfiguredAppRow
          app={{
            nameOrBundleId: `Khan Academy`,
            appIconUrl: `/example-app-icons/khan-academy.webp`,
          }}
          onRemove={noop}
        />
      </StorySection>
      <StorySection title="Schedule button">
        <ScheduleButton schedule={weekdaySchedule} setSchedule={noop} />
        <ScheduleButton setSchedule={noop} />
      </StorySection>
    </StoryCanvas>
  ),
};

export const AddBlockedDomain = {
  name: 'Add blocked domain modal',
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <AddBlockedDomainModal open onOpenChange={noop} onAdd={noop} />
    </StoryCanvas>
  ),
};

export const AddKeychains = {
  name: 'Add keychains slide-over',
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <AddKeychainSlideOver
        open
        onOpenChange={noop}
        personName="Jude"
        keychains={keychains}
        assignedKeychainIds={[`keychain-school`]}
        onAdd={noop}
      />
    </StoryCanvas>
  ),
};

export const AddMacApps = {
  name: 'Add Mac apps slide-over',
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <AddMacAppSlideOver
        open
        type="blocked"
        personName="Jude"
        installedApps={installedMacApps}
        blockedApps={[]}
        unrestrictedApps={[]}
        onOpenChange={noop}
        onAdd={noop}
      />
    </StoryCanvas>
  ),
};

export const AddAllowedAlbums = {
  name: 'Add allowed albums slide-over',
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <AddAllowedAlbumsSlideOver
        open
        onOpenChange={noop}
        catalog={albums}
        allowedAlbums={[albums[0]!]}
        onAdd={noop}
      />
    </StoryCanvas>
  ),
};
