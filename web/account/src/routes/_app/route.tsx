import { Sidebar, SidebarItem, SidebarLayout, SidebarSection } from '@gertrude/ui';
import { Outlet, createFileRoute, redirect, useLocation } from '@tanstack/react-router';
import { LogOutIcon, ScanEyeIcon, UsersIcon } from 'lucide-react';
import React from 'react';
import { isAuthed } from '#/pairql/auth';

const AuthedLayout: React.FC = () => {
  const { pathname } = useLocation();
  const isSelected = (href: string): boolean =>
    pathname === href || pathname.startsWith(`${href}/`);

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
            title="Activity"
            icon={ScanEyeIcon}
            href="/activity"
            selected={isSelected(`/activity`)}
          />
        </SidebarSection>
      </Sidebar>
    </SidebarLayout>
  );
};

export const Route = createFileRoute(`/_app`)({
  beforeLoad: () => {
    if (!isAuthed()) {
      throw redirect({ to: `/login` });
    }
  },
  component: AuthedLayout,
});
