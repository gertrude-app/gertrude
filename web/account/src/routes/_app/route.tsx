import {
  Outlet,
  createFileRoute,
  redirect,
  useLocation,
  useNavigate,
} from '@tanstack/react-router';
import React from 'react';
import type { IOSSetupApp, SetupStepId } from '#/components/onboarding/setupApps';
import ConnectMacModal from '#/components/devices/ConnectMacModal';
import InstallIOSAppModal from '#/components/devices/InstallIOSAppModal';
import { useConnectMac } from '#/components/devices/useConnectMac';
import AuthedAppLayout from '#/components/layout/AuthedAppLayout';
import SetupChecklist from '#/components/onboarding/SetupChecklist';
import { appStoreUrls, setupApps } from '#/components/onboarding/setupApps';
import { setupChecklist, setupProgress } from '#/lib/accountSetup';
import { authRedirectForPath } from '#/lib/authRedirect';
import { useShareLink } from '#/lib/shareLink';
import { isAuthed } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const AuthedLayout: React.FC = () => {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const unlockRequests = useQuery(
    Key.unlockRequests,
    () => liveClient.getAccountUnlockRequestSummary(),
    { refetchInterval: 30_000 },
  );
  const suspensionRequests = useQuery(
    Key.suspensionRequests,
    () => liveClient.getSuspensionRequests(),
    { refetchInterval: 30_000 },
  );
  const setupQuery = useQuery(Key.accountSetup, () => liveClient.getAccountSetup(), {
    refetchInterval: ({ state }) =>
      state.data && setupChecklist(state.data) ? 30_000 : false,
  });
  const checklist = setupQuery.data && setupChecklist(setupQuery.data);
  const peopleQuery = useQuery(Key.people, () => liveClient.getPeople(), {
    enabled: !!checklist,
  });
  const onlyPerson = peopleQuery.data?.length === 1 ? peopleQuery.data[0] : undefined;
  const [installApp, setInstallApp] = React.useState<IOSSetupApp>(`blocker`);
  const [installOpen, setInstallOpen] = React.useState(false);
  const shareLink = useShareLink();
  const { connectMac, modalProps: connectMacModalProps } = useConnectMac();
  const requestCount =
    (unlockRequests.data?.totalCount ?? 0) + (suspensionRequests.data?.length ?? 0);
  React.useEffect(() => {
    if (pathname !== `/settings/billing` && !pathname.startsWith(`/settings/billing/`)) {
      sessionStorage.removeItem(`pairingReturnPath`);
    }
  }, [pathname]);
  if (
    pathname.startsWith(`/connect/`) ||
    pathname === `/welcome` ||
    pathname === `/how-did-you-hear`
  )
    return <Outlet />;

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
        connectMac(
          (peopleQuery.data ?? []).map((person) => ({
            id: person.id,
            name: person.name,
          })),
        );
        return;
      default:
        shareLink.reset();
        setInstallApp(step);
        setInstallOpen(true);
    }
  };

  return (
    <AuthedAppLayout
      pathname={pathname}
      requestCount={requestCount}
      showMacSection={setupQuery.data?.completedApps.includes(`mac`) ?? true}
      menuProgress={checklist ? setupProgress(checklist) : undefined}
      sidebarContent={
        checklist && (
          <SetupChecklist
            selectedApps={checklist.selectedApps}
            includeNotifications={checklist.includeNotifications}
            completedSteps={checklist.completedSteps}
            onSelectStep={selectStep}
          />
        )
      }
    >
      <Outlet />
      <ConnectMacModal {...connectMacModalProps} />
      <InstallIOSAppModal
        open={installOpen}
        onOpenChange={setInstallOpen}
        app={installApp}
        personName={onlyPerson?.name}
        shareMethod={shareLink.method}
        copied={shareLink.copied}
        onShareLink={() => {
          const name = setupApps.find((app) => app.id === installApp)?.name ?? `Gertrude`;
          shareLink.share({
            title: name,
            text: `Install ${name} from the App Store`,
            url: appStoreUrls[installApp],
          });
        }}
      />
    </AuthedAppLayout>
  );
};

export const Route = createFileRoute(`/_app`)({
  beforeLoad: ({ location }) => {
    if (!isAuthed()) {
      const loginRedirect = authRedirectForPath(location.href);
      throw redirect({ to: `/login`, search: { redirect: loginRedirect } });
    }
  },
  component: AuthedLayout,
});
