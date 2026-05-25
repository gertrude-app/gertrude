import React from 'react';
import { createFileRoute, Outlet, useLocation } from '@tanstack/react-router';
import { Sidebar, SidebarItem, SidebarLayout, SidebarSection } from '@gertrude/ui';
import {
  LayoutGridIcon,
  LifeBuoyIcon,
  LogOutIcon,
  MonitorSmartphoneIcon,
  SettingsIcon,
  SparklesIcon,
  UsersIcon,
} from 'lucide-react';

const AuthedLayout: React.FC = () => {
  const { pathname } = useLocation();
  const isSelected = (href: string): boolean =>
    href === '/'
      ? pathname === href
      : pathname === href || pathname.startsWith(`${href}/`);

  return (
    <SidebarLayout content={<Outlet />}>
      <Sidebar
        logoUrl="/logo-wordmark.svg"
        logoWidth={140}
        bottomButton={{
          text: 'Sign out',
          href: '/signout',
          icon: LogOutIcon,
        }}
      >
        <SidebarSection title="Platform">
          <SidebarItem
            title="People"
            icon={UsersIcon}
            href="/people"
            selected={isSelected('/people')}
          />
          <SidebarItem
            title="Devices"
            icon={MonitorSmartphoneIcon}
            href="/devices"
            selected={isSelected('/devices')}
          />
          <SidebarItem
            title="Apps"
            icon={LayoutGridIcon}
            href="/apps"
            selected={isSelected('/apps')}
          />
          <SidebarItem
            title="Settings"
            icon={SettingsIcon}
            href="/settings/notifications"
            selected={isSelected('/settings')}
          />
        </SidebarSection>
        <SidebarSection title="Help">
          <SidebarItem
            title="Ask AI"
            icon={SparklesIcon}
            href="https://gertrude.app/docs"
          />
          <SidebarItem
            title="Support"
            icon={LifeBuoyIcon}
            href="https://gertrude.app/contact"
          />
        </SidebarSection>
      </Sidebar>
    </SidebarLayout>
  );
};

export const Route = createFileRoute('/_app')({
  component: AuthedLayout,
});
