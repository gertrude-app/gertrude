import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import React from 'react';
import type { LoadableState } from '#/components/types';
import PersonSettingsShellPage from '../people/PersonSettingsShellPage';
import MacSettingsPage, { type MacSettingsConfiguration } from './MacSettingsPage';

const meta = {
  title: 'Account/Pages/People/Person Mac Settings',
  component: MacSettingsPage,
  parameters: { layout: 'fullscreen' },
};

export default meta;

interface MacSettingsStoryProps {
  initialState: LoadableState<MacSettingsConfiguration>;
  savingMonitoring?: boolean;
}

const defaultSettings: MacSettingsConfiguration = {
  keyloggingEnabled: true,
  showSuspensionActivity: true,
  screenshots: {
    enabled: true,
    resolution: 1080,
    frequency: 120,
    canBeDisabled: true,
  },
  hasMacDevices: true,
};

const MacSettingsStory: React.FC<MacSettingsStoryProps> = ({
  initialState,
  savingMonitoring,
}) => {
  const [state, setState] = React.useState(initialState);

  return (
    <StoryScreen>
      <PersonSettingsShellPage
        personName="Jude"
        peopleHref="/people"
        baseHref="/people/person-1"
        selectedHref="/people/person-1/mac-settings"
      >
        <MacSettingsPage
          state={state}
          savingMonitoring={savingMonitoring}
          onSaveMonitoring={(configuration) => {
            if (state.status === `success`) {
              setState({
                status: `success`,
                data: {
                  ...state.data,
                  keyloggingEnabled: configuration.keyloggingEnabled,
                  showSuspensionActivity: configuration.showSuspensionActivity,
                  screenshots: {
                    ...state.data.screenshots,
                    ...configuration.screenshots,
                  },
                },
              });
            }
          }}
        />
      </PersonSettingsShellPage>
    </StoryScreen>
  );
};

export const Monitoring = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory initialState={{ status: `success`, data: defaultSettings }} />
  ),
};

export const UnsavedChanges = {
  name: 'Unsaved changes',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory initialState={{ status: `success`, data: defaultSettings }} />
  ),
  play: ({ canvasElement }: { canvasElement: HTMLElement }) => {
    const toggle = canvasElement.querySelector<HTMLButtonElement>(
      `[role="switch"][aria-label="Enable Keylogging"]`,
    );
    if (!toggle) {
      throw new globalThis.Error(`Enable Keylogging toggle not found`);
    }
    toggle.click();
    toggle.blur();
  },
};

export const ScreenshotsRequired = {
  name: 'Screenshots required while filtering is disabled',
  parameters: { ...galleryParameters, screenshotsAt: ['desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: {
          ...defaultSettings,
          screenshots: { ...defaultSettings.screenshots, canBeDisabled: false },
        },
      }}
    />
  ),
};

export const Loading = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => <MacSettingsStory initialState={{ status: `loading` }} />,
};

export const Error = {
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `error`,
        message: `Check your connection and try again.`,
        onRetry: () => {},
      }}
    />
  ),
};

export const NoConnectedMac = {
  name: 'No connected Mac',
  parameters: { ...galleryParameters, screenshotsAt: ['mobile', 'desktop'] },
  render: () => (
    <MacSettingsStory
      initialState={{
        status: `success`,
        data: { ...defaultSettings, hasMacDevices: false },
      }}
    />
  ),
};
