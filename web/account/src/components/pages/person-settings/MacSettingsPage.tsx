import { Button, EmptyState, HStack, Input, Skeleton, Stack, VStack } from '@gertrude/ui';
import { CircleAlertIcon, LaptopIcon, RefreshCwIcon } from 'lucide-react';
import React from 'react';
import type { LoadableState } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import PersonSettingsExpandableSection from '#/components/person-settings/PersonSettingsExpandableSection';
import SettingsRow from '#/components/person-settings/SettingsRow';

export interface MacSettingsConfiguration {
  keyloggingEnabled: boolean;
  showSuspensionActivity: boolean;
  screenshots: {
    enabled: boolean;
    resolution: number;
    frequency: number;
    canBeDisabled: boolean;
  };
  hasMacDevices: boolean;
}

export interface MacMonitoringConfiguration {
  keyloggingEnabled: boolean;
  showSuspensionActivity: boolean;
  screenshots: {
    enabled: boolean;
    resolution: number;
    frequency: number;
  };
}

interface Props {
  state: LoadableState<MacSettingsConfiguration>;
  savingMonitoring?: boolean;
  onSaveMonitoring: (configuration: MacMonitoringConfiguration) => void;
}

interface MonitoringSettingsProps {
  settings: MacSettingsConfiguration;
  saving: boolean;
  onSave: (configuration: MacMonitoringConfiguration) => void;
}

const integerAtLeast = (value: string, minimum: number): number | undefined => {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed >= minimum ? parsed : undefined;
};

const MonitoringSettings: React.FC<MonitoringSettingsProps> = ({
  settings,
  saving,
  onSave,
}) => {
  const [keyloggingEnabled, setKeyloggingEnabled] = React.useState(
    settings.keyloggingEnabled,
  );
  const [screenshotsEnabled, setScreenshotsEnabled] = React.useState(
    settings.screenshots.enabled,
  );
  const [showSuspensionActivity, setShowSuspensionActivity] = React.useState(
    settings.showSuspensionActivity,
  );
  const [frequencyDraft, setFrequencyDraft] = React.useState(
    String(settings.screenshots.frequency),
  );
  const [resolutionDraft, setResolutionDraft] = React.useState(
    String(settings.screenshots.resolution),
  );
  const frequency = integerAtLeast(frequencyDraft, 10);
  const resolution = integerAtLeast(resolutionDraft, 1);
  const frequencyError =
    frequencyDraft.trim() === ``
      ? `Frequency is required.`
      : frequency === undefined
        ? `Enter a whole number of at least 10 seconds.`
        : undefined;
  const resolutionError =
    resolutionDraft.trim() === ``
      ? `Resolution is required.`
      : resolution === undefined
        ? `Enter a positive whole number.`
        : undefined;
  const hasUnsavedChanges =
    keyloggingEnabled !== settings.keyloggingEnabled ||
    screenshotsEnabled !== settings.screenshots.enabled ||
    showSuspensionActivity !== settings.showSuspensionActivity ||
    frequencyDraft !== String(settings.screenshots.frequency) ||
    resolutionDraft !== String(settings.screenshots.resolution);
  const screenshotRequirementMet =
    settings.screenshots.canBeDisabled || screenshotsEnabled;
  const canSave =
    hasUnsavedChanges &&
    frequency !== undefined &&
    resolution !== undefined &&
    screenshotRequirementMet;

  React.useEffect(() => {
    setKeyloggingEnabled(settings.keyloggingEnabled);
    setScreenshotsEnabled(settings.screenshots.enabled);
    setShowSuspensionActivity(settings.showSuspensionActivity);
    setFrequencyDraft(String(settings.screenshots.frequency));
    setResolutionDraft(String(settings.screenshots.resolution));
  }, [
    settings.keyloggingEnabled,
    settings.showSuspensionActivity,
    settings.screenshots.enabled,
    settings.screenshots.frequency,
    settings.screenshots.resolution,
  ]);

  const save = (): void => {
    if (
      !hasUnsavedChanges ||
      frequency === undefined ||
      resolution === undefined ||
      !screenshotRequirementMet ||
      saving
    ) {
      return;
    }

    setFrequencyDraft(String(frequency));
    setResolutionDraft(String(resolution));
    onSave({
      keyloggingEnabled,
      showSuspensionActivity,
      screenshots: {
        enabled: screenshotsEnabled,
        resolution,
        frequency,
      },
    });
  };

  return (
    <PersonSettingsExpandableSection
      title="Monitoring"
      defaultExpanded
      hasUnsavedChanges={hasUnsavedChanges}
      previewChips={[
        {
          title: `Keylogging`,
          values: [
            {
              text: keyloggingEnabled ? `On` : `Off`,
              color: keyloggingEnabled ? `violet` : `neutral`,
            },
          ],
        },
        {
          title: `Screenshots`,
          values: [
            {
              text: screenshotsEnabled
                ? frequency === undefined
                  ? `On`
                  : `Every ${frequency}s`
                : `Off`,
              color: screenshotsEnabled ? `violet` : `neutral`,
            },
          ],
        },
      ]}
    >
      <form
        onSubmit={(event) => {
          event.preventDefault();
          save();
        }}
      >
        <VStack gap={3}>
          <SettingsRow
            type="toggle"
            title="Enable Keylogging"
            description="Sends reports of all keystrokes to your review."
            enabled={keyloggingEnabled}
            disabled={saving}
            setEnabled={setKeyloggingEnabled}
          />
          <SettingsRow
            type="toggle"
            title="Enable Screenshots"
            description={
              settings.screenshots.canBeDisabled
                ? `Periodically take a screenshot and upload it for your review.`
                : `Screenshots are required when internet filtering is disabled.`
            }
            enabled={screenshotsEnabled}
            disabled={
              saving || (screenshotsEnabled && !settings.screenshots.canBeDisabled)
            }
            setEnabled={(enabled) => {
              setScreenshotsEnabled(enabled);
              if (!enabled) {
                setFrequencyDraft(String(settings.screenshots.frequency));
                setResolutionDraft(String(settings.screenshots.resolution));
              }
            }}
          >
            <Stack
              direction={{ default: `vertical`, '@lg/main': `horizontal` }}
              gap={{ default: 4, '@lg/main': 2 }}
            >
              <Input
                label="Average Frequency"
                suffix="seconds"
                prefix="Every"
                type="number"
                value={frequencyDraft}
                setValue={setFrequencyDraft}
                min={10}
                step={1}
                error={frequencyError}
                helperText="The actual frequency will be randomized around the average you provide."
                disabled={saving}
                className="@lg/main:w-1/2"
              />
              <Input
                label="Resolution"
                suffix="px"
                type="number"
                value={resolutionDraft}
                setValue={setResolutionDraft}
                min={1}
                step={1}
                error={resolutionError}
                disabled={saving}
                className="@lg/main:w-1/2"
              />
            </Stack>
          </SettingsRow>
          {(keyloggingEnabled || screenshotsEnabled) && (
            <SettingsRow
              type="toggle"
              title="Emphasize Filter Suspension Activity"
              description="Visually highlight activity that is recorded while filter is suspended."
              enabled={showSuspensionActivity}
              disabled={saving}
              setEnabled={setShowSuspensionActivity}
            />
          )}
          <HStack justify="end">
            <Button
              type="submit"
              variant="primary"
              disabled={!canSave || saving}
              loading={saving}
              className="w-full @lg/main:w-auto"
            >
              Save Changes
            </Button>
          </HStack>
        </VStack>
      </form>
    </PersonSettingsExpandableSection>
  );
};

const MacSettingsPage: React.FC<Props> = ({
  state,
  savingMonitoring = false,
  onSaveMonitoring,
}) => {
  if (state.status === `loading`) {
    return (
      <CardContainer className="flex flex-col gap-4">
        <span role="status" className="sr-only">
          Loading Mac settings
        </span>
        <Skeleton className="h-14 w-full" radius="large" />
        <Skeleton className="h-28 w-full" radius="large" />
      </CardContainer>
    );
  }

  if (state.status === `error`) {
    return (
      <CardContainer>
        <div role="alert">
          <EmptyState
            icon={CircleAlertIcon}
            title="Couldn't load Mac settings"
            description={state.message}
            button={{
              text: `Try again`,
              type: `button`,
              onClick: state.onRetry,
              icon: RefreshCwIcon,
            }}
            className="bg-white"
          />
        </div>
      </CardContainer>
    );
  }

  if (!state.data.hasMacDevices) {
    return (
      <CardContainer>
        <EmptyState
          icon={LaptopIcon}
          title="No Mac connected"
          description="Connect a Mac to configure its monitoring settings."
          className="bg-white"
        />
      </CardContainer>
    );
  }

  return (
    <CardContainer className="flex flex-col gap-4">
      {savingMonitoring && (
        <span role="status" className="sr-only">
          Saving monitoring settings
        </span>
      )}
      <MonitoringSettings
        settings={state.data}
        saving={savingMonitoring}
        onSave={onSaveMonitoring}
      />
    </CardContainer>
  );
};

export default MacSettingsPage;
