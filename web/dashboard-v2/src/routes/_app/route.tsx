import { Sidebar, SidebarItem, SidebarLayout, SidebarSection } from '@gertrude/ui';
import { Outlet, createFileRoute, useLocation } from '@tanstack/react-router';
import {
  InboxIcon,
  KeyIcon,
  LaptopIcon,
  LogOutIcon,
  MusicIcon,
  ScanEyeIcon,
  SettingsIcon,
  SmartphoneIcon,
  UsersIcon,
} from 'lucide-react';
import React from 'react';
import { getAppChrome, useMockDataSelector } from '#/lib/mock';

const AuthedLayout: React.FC = () => {
  const { pathname } = useLocation();
  const { requestCount } = useMockDataSelector(getAppChrome);
  const isSelected = (href: string): boolean =>
    href === `/`
      ? pathname === href
      : pathname === href || pathname.startsWith(`${href}/`);

  return (
    <SidebarLayout content={<Outlet />}>
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
            title="Settings"
            icon={SettingsIcon}
            href="/settings/notifications"
            selected={isSelected(`/settings`)}
          />
        </SidebarSection>
        <SidebarSection title="Computers">
          <SidebarItem
            title="Macs"
            icon={LaptopIcon}
            href="/macs"
            selected={isSelected(`/macs`)}
          />
          <SidebarItem
            title="Requests"
            icon={InboxIcon}
            href="/requests"
            selected={isSelected(`/requests`)}
            badgeCount={requestCount}
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
        </SidebarSection>
        <SidebarSection title="iPhones & iPads">
          <SidebarItem
            title="Devices"
            icon={SmartphoneIcon}
            href="/ios-devices"
            selected={isSelected(`/ios-devices`)}
          />
          <SidebarItem
            title="Media"
            icon={MusicIcon}
            href="/media"
            selected={isSelected(`/media`)}
          />
        </SidebarSection>
      </Sidebar>
    </SidebarLayout>
  );
};

export const Route = createFileRoute(`/_app`)({
  component: AuthedLayout,
});
