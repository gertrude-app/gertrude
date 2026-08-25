import { EmptyState, PageHeading, Skeleton, VStack } from '@gertrude/ui';
import {
  Outlet,
  createFileRoute,
  useLocation,
  useNavigate,
} from '@tanstack/react-router';
import { CircleAlertIcon, RefreshCwIcon } from 'lucide-react';
import React from 'react';
import DashboardPage from '#/components/layout/DashboardPage';
import SettingsShellPage from '#/components/pages/settings/SettingsShellPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const SettingsRoute: React.FC = () => {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const query = useQuery(Key.accountSettings, () => liveClient.getAccountSettings());

  if (query.data === undefined && query.isError) {
    return (
      <DashboardPage heading={<PageHeading title="Settings" />}>
        <EmptyState
          icon={CircleAlertIcon}
          title="Couldn't load settings"
          description={query.error.userMessage ?? `Check your connection and try again.`}
          button={{
            text: `Try again`,
            type: `button`,
            onClick: () => void query.refetch(),
            icon: RefreshCwIcon,
          }}
          className="bg-white"
        />
      </DashboardPage>
    );
  }

  if (query.data === undefined) {
    return (
      <DashboardPage heading={<PageHeading title="Settings" />}>
        <VStack gap={4}>
          <Skeleton radius="large" className="h-12 w-full" />
          <Skeleton radius="large" className="h-40 w-full" />
          <Skeleton radius="large" className="h-64 w-full" />
        </VStack>
      </DashboardPage>
    );
  }

  return (
    <SettingsShellPage
      email={query.data.email}
      selectedHref={
        pathname.startsWith(`/settings/billing`)
          ? `/settings/billing`
          : `/settings/notifications`
      }
      notificationsHref="/settings/notifications"
      billingHref="/settings/billing"
      onChangePassword={() => void navigate({ to: `/reset-password` })}
    >
      <Outlet />
    </SettingsShellPage>
  );
};

export const Route = createFileRoute(`/_app/settings`)({
  component: SettingsRoute,
});
