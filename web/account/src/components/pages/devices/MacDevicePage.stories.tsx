import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { MacDeviceDetails, ReleaseChannel } from '#/components/devices/types';
import MacDevicePage from './MacDevicePage';

const device: MacDeviceDetails = {
  id: `mac-family`,
  name: `Family MacBook`,
  modelName: `14-inch MacBook Pro (2023)`,
  modelIdentifier: `Mac14,9`,
  macOSVersion: `26.0`,
  appVersion: `2.9.7`,
  releaseChannel: `stable`,
  targetVersions: {
    stable: `2.9.7`,
    beta: `2.10.0`,
    canary: `2.11.0`,
  },
  people: [
    { id: `person-jude`, name: `Jude`, status: { case: `filterOn` } },
    {
      id: `person-mabel`,
      name: `Mabel`,
      status: { case: `filterSuspended` },
    },
  ],
};

const MacDeviceStory: React.FC<{ initialDevice?: MacDeviceDetails }> = ({
  initialDevice = device,
}) => {
  const [savedDevice, setSavedDevice] = React.useState(initialDevice);
  const [nameDraft, setNameDraft] = React.useState(savedDevice.name ?? ``);
  const [releaseChannelDraft, setReleaseChannelDraft] = React.useState<ReleaseChannel>(
    savedDevice.releaseChannel,
  );

  return (
    <StoryScreen>
      <MacDevicePage
        state={{ status: `success`, data: savedDevice }}
        nameDraft={nameDraft}
        setNameDraft={setNameDraft}
        releaseChannelDraft={releaseChannelDraft}
        setReleaseChannelDraft={setReleaseChannelDraft}
        onSave={() =>
          setSavedDevice({
            ...savedDevice,
            name: nameDraft.trim() || undefined,
            releaseChannel: releaseChannelDraft,
          })
        }
      />
    </StoryScreen>
  );
};

const meta = {
  title: 'Account/Pages/Devices/Mac Device',
  component: MacDevicePage,
  parameters: { layout: 'fullscreen' },
};

export default meta;

export const Default = {
  parameters: {
    ...galleryParameters,
    screenshotsAt: ['mobile', 'medium', 'desktop'],
  },
  render: () => <MacDeviceStory />,
};

export const WithoutCustomNameOrVersion = {
  name: 'Without custom name or version',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacDeviceStory
      initialDevice={{
        ...device,
        name: undefined,
        macOSVersion: undefined,
        appVersion: undefined,
        targetVersions: {},
        people: [{ id: `person-jude`, name: `Jude`, status: { case: `offline` } }],
      }}
    />
  ),
};

export const Loading = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <MacDevicePage
        state={{ status: `loading` }}
        nameDraft=""
        setNameDraft={() => {}}
        releaseChannelDraft="stable"
        setReleaseChannelDraft={() => {}}
        onSave={() => {}}
      />
    </StoryScreen>
  ),
};

export const Error = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <MacDevicePage
        state={{
          status: `error`,
          message: `Check your connection and try again.`,
          onRetry: () => {},
        }}
        nameDraft=""
        setNameDraft={() => {}}
        releaseChannelDraft="stable"
        setReleaseChannelDraft={() => {}}
        onSave={() => {}}
      />
    </StoryScreen>
  ),
};
