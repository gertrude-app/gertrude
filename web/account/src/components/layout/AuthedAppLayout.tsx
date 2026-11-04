import { Sidebar, SidebarItem, SidebarLayout, SidebarSection } from '@gertrude/ui';
import {
  InboxIcon,
  KeyIcon,
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
  sidebarContent?: React.ReactNode;
  showMacSection?: boolean;
}

const AuthedAppLayout: React.FC<Props> = ({
  children,
  pathname,
  requestCount,
  sidebarContent,
  showMacSection = true,
}) => {
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
        bottomContent={sidebarContent}
        footer={
          <SidebarItem
            title="Settings"
            icon={SettingsIcon}
            href="/settings"
            selected={isSelected(`/settings`)}
          />
        }
      >
        <SidebarSection title={showMacSection ? `Platform` : undefined}>
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
            title="Security"
            icon={ShieldCheckIcon}
            href="/security-events"
            selected={isSelected(`/security-events`)}
          />
        </SidebarSection>
        {showMacSection && (
          <SidebarSection title="Mac">
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
          </SidebarSection>
        )}
      </Sidebar>
    </SidebarLayout>
  );
};

export default AuthedAppLayout;
