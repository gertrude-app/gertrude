import { Outlet, createFileRoute, redirect, useLocation } from '@tanstack/react-router';
import React from 'react';
import AuthedAppLayout from '#/components/layout/AuthedAppLayout';
import { authRedirectForPath } from '#/lib/authRedirect';
import { isAuthed } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const AuthedLayout: React.FC = () => {
  const { pathname } = useLocation();
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
  const requestCount =
    (unlockRequests.data?.totalCount ?? 0) + (suspensionRequests.data?.length ?? 0);
  React.useEffect(() => {
    if (pathname !== `/settings/billing` && !pathname.startsWith(`/settings/billing/`)) {
      sessionStorage.removeItem(`pairingReturnPath`);
    }
  }, [pathname]);
  if (pathname.startsWith(`/connect/`)) return <Outlet />;

  return (
    <AuthedAppLayout pathname={pathname} requestCount={requestCount}>
      <Outlet />
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
