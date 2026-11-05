import { toast } from '@gertrude/ui';
import { useNavigate } from '@tanstack/react-router';
import React from 'react';
import type { IOSSetupApp, SetupStepId } from '#/components/onboarding/setupApps';
import ConnectMacModal from '#/components/devices/ConnectMacModal';
import InstallIOSAppModal from '#/components/devices/InstallIOSAppModal';
import { useConnectMac } from '#/components/devices/useConnectMac';
import SetupChecklist from '#/components/onboarding/SetupChecklist';
import { setupChecklist, setupProgress } from '#/lib/accountSetup';
import { gertrudeApps } from '#/lib/gertrudeApps';
import { useShareLink } from '#/lib/shareLink';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

export function useSetupChecklist(pathname: string): {
  sidebarContent: React.ReactNode;
  menuProgress?: { completed: number; total: number };
  showMacSection: boolean;
  modals: React.ReactNode;
} {
  const navigate = useNavigate();
  const setupQuery = useQuery(Key.accountSetup, () => liveClient.getAccountSetup(), {
    refetchInterval: ({ state }) =>
      state.data && setupChecklist(state.data) ? 30_000 : false,
  });
  const checklist = setupQuery.data && setupChecklist(setupQuery.data);
  const peopleQuery = useQuery(Key.people, () => liveClient.getPeople(), {
    enabled: !!checklist,
  });
  const onlyPerson = peopleQuery.data?.length === 1 ? peopleQuery.data[0] : undefined;
  const loadPeople = async (): Promise<NonNullable<typeof peopleQuery.data>> => {
    const { data } = await peopleQuery.refetch({ throwOnError: true });
    if (!data) throw new Error(`people unavailable`);
    return data;
  };
  const [installApp, setInstallApp] = React.useState<IOSSetupApp>(`blocker`);
  const [installOpen, setInstallOpen] = React.useState(false);
  const shareLink = useShareLink();
  const { connectMac, modalProps: connectMacModalProps } = useConnectMac(pathname);
  React.useEffect(() => {
    setInstallOpen(false);
  }, [pathname]);

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
        shareLink.reset();
        setInstallApp(step);
        setInstallOpen(true);
    }
  };

  return {
    showMacSection: setupQuery.data?.completedApps.includes(`mac`) ?? true,
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
        <InstallIOSAppModal
          open={installOpen}
          onOpenChange={setInstallOpen}
          app={installApp}
          personName={onlyPerson?.name}
          shareMethod={shareLink.method}
          copied={shareLink.copied}
          onShareLink={() => {
            const { name, appStoreUrl } = gertrudeApps[installApp];
            shareLink.share({
              title: name,
              text: `Install ${name} from the App Store`,
              url: appStoreUrl,
            });
          }}
        />
      </>
    ),
  };
}
