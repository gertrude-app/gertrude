import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type { LoadableState } from '#/components/types';
import MacSettingsPage, {
  type MacMonitoringConfiguration,
  type MacSettingsConfiguration,
} from '#/components/pages/person-settings/MacSettingsPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const MacSettingsRoute: React.FC = () => {
  const { personId } = Route.useParams();
  const settingsKey = Key.personMacSettings(personId);
  const settingsQuery = useQuery(settingsKey, () =>
    liveClient.getPersonMacSettings({ personId }),
  );
  const updateMonitoring = useMutation(liveClient.updatePersonMacMonitoringSettings, {
    invalidating: [settingsKey, Key.activity],
    toast: {
      loading: `Saving monitoring settings…`,
      success: `Monitoring settings saved`,
      error: `Failed to save monitoring settings`,
    },
  });

  const state: LoadableState<MacSettingsConfiguration> =
    settingsQuery.data !== undefined
      ? { status: `success`, data: settingsQuery.data }
      : settingsQuery.isError
        ? {
            status: `error`,
            message:
              settingsQuery.error.userMessage ?? `Check your connection and try again.`,
            onRetry: () => void settingsQuery.refetch(),
          }
        : { status: `loading` };

  return (
    <MacSettingsPage
      state={state}
      savingMonitoring={updateMonitoring.isPending}
      onSaveMonitoring={(configuration: MacMonitoringConfiguration) => {
        if (updateMonitoring.isPending) {
          return;
        }

        updateMonitoring.mutate({
          personId,
          keyloggingEnabled: configuration.keyloggingEnabled,
          showSuspensionActivity: configuration.showSuspensionActivity,
          screenshotsEnabled: configuration.screenshots.enabled,
          screenshotsResolution: configuration.screenshots.resolution,
          screenshotsFrequency: configuration.screenshots.frequency,
        });
      }}
    />
  );
};

export const Route = createFileRoute(`/_app/people/$personId/mac-settings`)({
  component: MacSettingsRoute,
});
