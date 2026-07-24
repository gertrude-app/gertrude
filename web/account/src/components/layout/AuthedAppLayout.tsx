import { Sidebar, SidebarItem, SidebarLayout, SidebarSection } from '@gertrude/ui';
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

interface Props {
  children: React.ReactNode;
  pathname: string;
  requestCount: number;
}

const AuthedAppLayout: React.FC<Props> = ({ children, pathname, requestCount }) => {
  const isSelected = (href: string): boolean =>
    href === `/`
      ? pathname === href
      : pathname === href || pathname.startsWith(`${href}/`);

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
            href="/requests/suspension"
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

export default AuthedAppLayout;
