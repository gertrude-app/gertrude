import { toast } from '@gertrude/ui';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import type { SetupApp } from '#/components/onboarding/setupApps';
import ChooseAppsPage from '#/components/pages/onboarding/ChooseAppsPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useOptimism, useQuery } from '#/pairql/query';

const WelcomeRoute: React.FC = () => {
  const navigate = useNavigate();
  const optimism = useOptimism();
  const setupQuery = useQuery(Key.accountSetup, () => liveClient.getAccountSetup());
  const [selectedApps, setSelectedApps] = React.useState<SetupApp[]>();
  const saveApps = useMutation(liveClient.setAccountSetupApps, {
    invalidating: [Key.accountSetup],
    onError: (error) => toast.error(error.userMessage ?? `Couldn’t save your choice`),
  });

  const save = (apps: SetupApp[]): void => {
    if (saveApps.isPending) return;
    saveApps.mutate(
      { apps },
      {
        onSuccess: () => {
          optimism.modify(Key.accountSetup, (setup) => ({
            ...setup,
            selectedApps: apps,
          }));
          void navigate({ to: `/people`, replace: true });
        },
      },
    );
  };

  return (
    <ChooseAppsPage
      selectedApps={selectedApps ?? setupQuery.data?.selectedApps ?? []}
      onSelectedAppsChange={setSelectedApps}
      onContinue={save}
      onSkip={() => save([])}
    />
  );
};

export const Route = createFileRoute(`/_app/welcome`)({
  component: WelcomeRoute,
});
