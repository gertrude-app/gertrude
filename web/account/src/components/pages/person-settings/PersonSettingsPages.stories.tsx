import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { PersonIosSettingsConfiguration } from '#/components/types';
import PersonSettingsShellPage from '../people/PersonSettingsShellPage';
import IosSettingsComingSoonPage from './IosSettingsComingSoonPage';
import IosSettingsPage from './IosSettingsPage';
import { albums, iosSettings } from '#/components/storybook/fixtures';

const meta = {
  title: 'Account/Pages/People/Person Settings',
  parameters: { layout: 'fullscreen' },
};

export default meta;

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
        <IosSettingsComingSoonPage />
      </PersonSettingsShellPage>
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

export const IosAllSectionsExpanded = {
  name: 'iPhone and iPad all sections expanded',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <StoryScreen className="p-12" innerClassName="max-w-[1200px]">
      <IosSettingsStory defaultExpandedSections={[`blocker`, `music`, `podcasts`]} />
    </StoryScreen>
  ),
};
