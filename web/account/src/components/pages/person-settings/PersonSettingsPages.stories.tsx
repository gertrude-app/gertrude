import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type {
  PersonIosSettingsConfiguration,
  PersonMacSettingsConfiguration,
} from '#/components/types';
import PersonSettingsShellPage from '../people/PersonSettingsShellPage';
import IosSettingsPage from './IosSettingsPage';
import MacSettingsPage from './MacSettingsPage';
import PersonSettingsComingSoonPage from './PersonSettingsComingSoonPage';
import {
  albums,
  installedMacApps,
  iosSettings,
  keychains,
  macSettings,
} from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Pages/People/Person Settings',
  parameters: { layout: 'fullscreen' },
};

export default meta;

const MacSettingsStory: React.FC<{
  defaultExpandedSections?: React.ComponentProps<
    typeof MacSettingsPage
  >[`defaultExpandedSections`];
}> = ({ defaultExpandedSections }) => {
  const [config, setConfig] = React.useState<PersonMacSettingsConfiguration>(macSettings);

  return (
    <MacSettingsPage
      config={config}
      personName="Jude"
      hasMacDevices
      assignedKeychains={keychains.filter((keychain) =>
        config.keychainIds.includes(keychain.id),
      )}
      allKeychains={keychains}
      installedMacApps={installedMacApps}
      defaultExpandedSections={defaultExpandedSections}
      patchConfig={(patch) => setConfig((current) => ({ ...current, ...patch }))}
    />
  );
};

const IosSettingsStory: React.FC<{
  defaultExpandedSections?: React.ComponentProps<
    typeof IosSettingsPage
  >[`defaultExpandedSections`];
}> = ({ defaultExpandedSections }) => {
  const [config, setConfig] = React.useState<PersonIosSettingsConfiguration>(iosSettings);

  return (
    <IosSettingsPage
      config={config}
      hasIosDevices
      albumCatalog={albums}
      defaultExpandedSections={defaultExpandedSections}
      patchConfig={(patch) => setConfig((current) => ({ ...current, ...patch }))}
    />
  );
};

export const MacComingSoon = {
  name: 'Mac coming soon',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryScreen>
      <PersonSettingsShellPage
        personName="Jude"
        peopleHref="/people"
        baseHref="/people/person-1"
        selectedHref="/people/person-1/mac-settings"
      >
        <PersonSettingsComingSoonPage platform="mac" />
      </PersonSettingsShellPage>
    </StoryScreen>
  ),
};

export const IosComingSoon = {
  name: 'iPhone and iPad coming soon',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryScreen>
      <PersonSettingsShellPage
        personName="Jude"
        peopleHref="/people"
        baseHref="/people/person-1"
        selectedHref="/people/person-1/ios-settings"
      >
        <PersonSettingsComingSoonPage platform="ios" />
      </PersonSettingsShellPage>
    </StoryScreen>
  ),
};

export const Mac = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryScreen className="p-12" innerClassName="max-w-[1200px]">
      <MacSettingsStory />
    </StoryScreen>
  ),
};

export const Ios = {
  name: 'iPhone and iPad',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryScreen className="p-12" innerClassName="max-w-[1200px]">
      <IosSettingsStory />
    </StoryScreen>
  ),
};

export const MacAllSectionsExpanded = {
  name: 'Mac all sections expanded',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryScreen className="p-12" innerClassName="max-w-[1200px]">
      <MacSettingsStory defaultExpandedSections={[`monitoring`, `filtering`, `apps`]} />
    </StoryScreen>
  ),
};

export const IosAllSectionsExpanded = {
  name: 'iPhone and iPad all sections expanded',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryScreen className="p-12" innerClassName="max-w-[1200px]">
      <IosSettingsStory defaultExpandedSections={[`blocker`, `music`, `podcasts`]} />
    </StoryScreen>
  ),
};
