import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import type {
  MacMonitoringConfiguration,
  MacSettingsConfiguration,
} from '#/components/pages/person-settings/MacSettingsPage.types';
import type { LoadableState } from '#/components/types';
import UnsavedChangesGuard from '#/components/UnsavedChangesGuard';
import MacSettingsPage from '#/components/pages/person-settings/MacSettingsPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const MacSettingsRoute: React.FC = () => {
  const { personId } = Route.useParams();
  const [hasUnsavedChanges, setHasUnsavedChanges] = React.useState(false);
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
  const updateInternetFiltering = useMutation(
    liveClient.updatePersonMacInternetFiltering,
    {
      invalidating: [settingsKey],
      toast: {
        loading: `Saving internet filtering settings…`,
        success: `Internet filtering settings saved`,
        error: `Failed to save internet filtering settings`,
      },
    },
  );

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
    <>
      <MacSettingsPage
        key={personId}
        state={state}
        savingMonitoring={updateMonitoring.isPending}
        savingInternetFiltering={updateInternetFiltering.isPending}
        onUnsavedChangesChange={setHasUnsavedChanges}
        onSaveMonitoring={(configuration: MacMonitoringConfiguration) =>
          updateMonitoring
            .mutateAsync({
              personId,
              keyloggingEnabled: configuration.keyloggingEnabled,
              showSuspensionActivity: configuration.showSuspensionActivity,
              screenshotsEnabled: configuration.screenshots.enabled,
              screenshotsResolution: configuration.screenshots.resolution,
              screenshotsFrequency: configuration.screenshots.frequency,
            })
            .then(() => undefined)
        }
        onSaveInternetFiltering={({
          filteringEnabled,
          keychains,
          alwaysBlockedGroupIds,
          customAlwaysBlockedRules,
        }) =>
          updateInternetFiltering
            .mutateAsync({
              personId,
              filteringEnabled,
              keychains,
              alwaysBlockedGroupIds,
              customAlwaysBlockedRules,
            })
            .then(() => undefined)
        }
      />
      <UnsavedChangesGuard
        hasUnsavedChanges={hasUnsavedChanges}
        description="Your Mac settings haven't been saved."
      />
    </>
  );
};

export const Route = createFileRoute(`/_app/people/$personId/mac-settings`)({
  component: MacSettingsRoute,
});
