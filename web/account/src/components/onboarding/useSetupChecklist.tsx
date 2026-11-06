import { toast } from '@gertrude/ui';
import { useNavigate } from '@tanstack/react-router';
import React from 'react';
import type { SetupStepId } from '#/components/onboarding/setupApps';
import ConnectMacModal from '#/components/devices/ConnectMacModal';
import InstallIOSAppModal from '#/components/devices/InstallIOSAppModal';
import { useConnectMac } from '#/components/devices/useConnectMac';
import { useInstallIOSApp } from '#/components/devices/useInstallIOSApp';
import SetupChecklist from '#/components/onboarding/SetupChecklist';
import { setupChecklist, setupProgress } from '#/lib/accountSetup';
import { getAccountId } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';
import { readSavedSetup, saveSetup } from '#/pairql/savedSetup';

export function useSetupChecklist(pathname: string): {
  sidebarContent: React.ReactNode;
  menuProgress?: { completed: number; total: number };
  showMacSection: boolean;
  modals: React.ReactNode;
} {
  const navigate = useNavigate();
  const [savedSetup] = React.useState(() => readSavedSetup(getAccountId()));
  const setupQuery = useQuery(Key.accountSetup, () => liveClient.getAccountSetup(), {
    placeholderData: savedSetup,
    refetchInterval: ({ state }) =>
      state.data && setupChecklist(state.data) ? 30_000 : false,
  });
  const checklist = setupQuery.data && setupChecklist(setupQuery.data);
  React.useEffect(() => {
    if (setupQuery.data && !setupQuery.isPlaceholderData) {
      saveSetup(getAccountId(), setupQuery.data);
    }
  }, [setupQuery.data, setupQuery.isPlaceholderData]);
  const peopleQuery = useQuery(Key.people, () => liveClient.getPeople(), {
    enabled: !!checklist,
  });
  const onlyPerson = peopleQuery.data?.length === 1 ? peopleQuery.data[0] : undefined;
  const loadPeople = async (): Promise<NonNullable<typeof peopleQuery.data>> => {
    const { data } = await peopleQuery.refetch({ throwOnError: true });
    if (!data) throw new Error(`people unavailable`);
    return data;
  };
  const { installIOSApp, modalProps: installModalProps } = useInstallIOSApp(
    onlyPerson?.name,
    pathname,
  );
  const { connectMac, modalProps: connectMacModalProps } = useConnectMac(pathname);

  const selectStep = (step: SetupStepId): void => {
    switch (step) {
      case `person`:
        void navigate({ to: `/people/new` });
        return;
      case `choose-apps`:
        void navigate({ to: `/welcome` });
        return;
      case `notifications`:
        void navigate({ to: `/settings/notifications` });
        return;
      case `mac`:
        void (peopleQuery.data ? Promise.resolve(peopleQuery.data) : loadPeople()).then(
          (people) => connectMac(people.map(({ id, name }) => ({ id, name }))),
          () => toast.error(`Couldn’t load your people. Try again.`),
        );
        return;
      default:
        installIOSApp(step);
    }
  };

  return {
    showMacSection: setupQuery.data
      ? setupQuery.data.completedApps.includes(`mac`)
      : setupQuery.isError,
    menuProgress: checklist ? setupProgress(checklist) : undefined,
    sidebarContent: checklist && (
      <SetupChecklist
        selectedApps={checklist.selectedApps}
        includeNotifications={checklist.includeNotifications}
        completedSteps={checklist.completedSteps}
        onSelectStep={selectStep}
        onChangeApps={() => void navigate({ to: `/welcome` })}
      />
    ),
    modals: (
      <>
        <ConnectMacModal {...connectMacModalProps} />
        <InstallIOSAppModal {...installModalProps} />
      </>
    ),
  };
}
