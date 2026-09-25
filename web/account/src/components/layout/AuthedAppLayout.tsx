import { Sidebar, SidebarItem, SidebarLayout, SidebarSection } from '@gertrude/ui';
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

interface Props {
  children: React.ReactNode;
  pathname: string;
  requestCount: number;
}

const AuthedAppLayout: React.FC<Props> = ({ children, pathname, requestCount }) => {
  const isSelected = (href: string): boolean =>
    pathname === href || pathname.startsWith(`${href}/`);

  return (
    <SidebarLayout
      content={children}
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
            href="/requests/unlock"
            selected={isSelected(`/requests`)}
            badgeCount={requestCount || undefined}
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

export default AuthedAppLayout;
