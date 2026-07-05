import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type {
  PersonIosSettingsConfiguration,
  PersonMacSettingsConfiguration,
} from '#/components/types';
import PersonBasicSettingsPage from '../people/PersonBasicSettingsPage';
import PersonSettingsShellPage from '../people/PersonSettingsShellPage';
import IosSettingsPage from './IosSettingsPage';
import MacSettingsPage from './MacSettingsPage';
import {
  albums,
  devices,
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

const MacSettingsStory: React.FC = () => {
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
      patchConfig={(patch) => setConfig((current) => ({ ...current, ...patch }))}
    />
  );
};

const IosSettingsStory: React.FC = () => {
  const [config, setConfig] = React.useState<PersonIosSettingsConfiguration>(iosSettings);

  return (
    <IosSettingsPage
      config={config}
      hasIosDevices
      albumCatalog={albums}
      patchConfig={(patch) => setConfig((current) => ({ ...current, ...patch }))}
    />
  );
};

export const Basic = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <PersonSettingsShellPage
        personName="Jude"
        peopleHref="/people"
        baseHref="/people/person-1"
        selectedHref="/people/person-1"
      >
        <PersonBasicSettingsPage
          personName="Jude"
          nameDraft="Jude"
          setNameDraft={() => {}}
          devices={devices.slice(0, 2)}
          deviceSettingsHref={(device) =>
            `/people/${device.personId}/${device.type}-settings`
          }
          onSaveName={() => {}}
          onAddDevice={() => {}}
          onDeletePerson={() => {}}
        />
      </PersonSettingsShellPage>
    </StoryScreen>
  ),
};

export const Mac = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen className="p-12" innerClassName="max-w-[1200px]">
      <MacSettingsStory />
    </StoryScreen>
  ),
};

export const Ios = {
  name: 'iPhone and iPad',
  parameters: galleryParameters,
  render: () => (
    <StoryScreen className="p-12" innerClassName="max-w-[1200px]">
      <IosSettingsStory />
    </StoryScreen>
  ),
};
