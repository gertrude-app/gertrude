import { Sidebar, SidebarItem, SidebarLayout, SidebarSection } from '@gertrude/ui';
import { Outlet, createFileRoute, redirect, useLocation } from '@tanstack/react-router';
import {
  InboxIcon,
  KeyIcon,
  LogOutIcon,
  MonitorSmartphoneIcon,
  ScanEyeIcon,
  SettingsIcon,
  ShieldCheckIcon,
  UsersIcon,
} from 'lucide-react';
import React from 'react';
import { authRedirectForPath } from '#/lib/authRedirect';
import { isAuthed } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

const AuthedLayout: React.FC = () => {
  const { pathname } = useLocation();
  const suspensionRequests = useQuery(
    Key.suspensionRequests,
    () => liveClient.getSuspensionRequests(),
    { refetchInterval: 30_000 },
  );
  const isSelected = (href: string): boolean =>
    pathname === href || pathname.startsWith(`${href}/`);

  return (
    <SidebarLayout
      content={<Outlet />}
      mobileLogo={<img src="/logo-wordmark.svg" alt="Gertrude" width={140} />}
    >
      <Sidebar
        logoUrl="/logo-wordmark.svg"
        logoWidth={140}
        bottomButton={{
          text: `Sign out`,
          href: `/signout`,
          icon: LogOutIcon,
        }}
      >
        <SidebarSection>
          <SidebarItem
            title="People"
            icon={UsersIcon}
            href="/people"
            selected={isSelected(`/people`)}
          />
          <SidebarItem
            title="Devices"
            icon={MonitorSmartphoneIcon}
            href="/devices"
            selected={isSelected(`/devices`)}
          />
          <SidebarItem
            title="Requests"
            icon={InboxIcon}
            href="/requests/suspension"
            selected={isSelected(`/requests`)}
            badgeCount={suspensionRequests.data?.length}
          />
          <SidebarItem
            title="Activity"
            icon={ScanEyeIcon}
            href="/activity"
            selected={isSelected(`/activity`)}
          />
          <SidebarItem
            title="Keychains"
            icon={KeyIcon}
            href="/keychains"
            selected={isSelected(`/keychains`)}
          />
          <SidebarItem
            title="Security"
            icon={ShieldCheckIcon}
            href="/security-events"
            selected={isSelected(`/security-events`)}
          />
          <SidebarItem
            title="Settings"
            icon={SettingsIcon}
            href="/settings"
            selected={isSelected(`/settings`)}
          />
        </SidebarSection>
      </Sidebar>
    </SidebarLayout>
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
