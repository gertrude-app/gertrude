import React from 'react';
import { LayoutGridIcon, DiamondIcon } from 'lucide-react';
import { Outlet, createRootRoute } from '@tanstack/react-router';
import SidebarLayout from '#/components/ui/fragments/sidebar/SidebarLayout';
import Sidebar from '#/components/ui/fragments/sidebar/Sidebar';
import SidebarSection from '#/components/ui/fragments/sidebar/SidebarSection';
import SidebarItem from '#/components/ui/fragments/sidebar/SidebarItem';
import '../styles.css';

const RootComponent: React.FC = () => (
  <SidebarLayout content={<Outlet />}>
    <Sidebar logoUrl="/gertrude-ui-logo.svg">
      <SidebarSection title="Fragments">
        <SidebarItem title="Sidebar" icon={LayoutGridIcon} to="/fragments/sidebar" />
      </SidebarSection>
      <SidebarSection title="Atoms">
        <SidebarItem title="Button" icon={DiamondIcon} to="/atoms/button" />
        <SidebarItem title="Input" icon={DiamondIcon} to="/atoms/input" />
      </SidebarSection>
    </Sidebar>
  </SidebarLayout>
);

export const Route = createRootRoute({
  component: RootComponent,
});
