import React from 'react';
import { DiamondIcon } from 'lucide-react';
import { Outlet, createRootRoute } from '@tanstack/react-router';
import SidebarLayout from '#/components/ui/sidebar/SidebarLayout';
import Sidebar from '#/components/ui/sidebar/Sidebar';
import SidebarSection from '#/components/ui/sidebar/SidebarSection';
import SidebarItem from '#/components/ui/sidebar/SidebarItem';
import '../styles.css';

const RootComponent: React.FC = () => (
  <SidebarLayout content={<Outlet />}>
    <Sidebar logoUrl="/gertrude-ui-logo.svg">
      <SidebarSection title="Components">
        <SidebarItem title="Badge" icon={DiamondIcon} to="/components/badge" />
        <SidebarItem title="Button" icon={DiamondIcon} to="/components/button" />
        <SidebarItem
          title="Dropdown Menu"
          icon={DiamondIcon}
          to="/components/dropdown-menu"
        />
        <SidebarItem title="Form" icon={DiamondIcon} to="/components/form" />
        <SidebarItem title="Input" icon={DiamondIcon} to="/components/input" />
        <SidebarItem title="Select" icon={DiamondIcon} to="/components/select" />
        <SidebarItem title="Sidebar" icon={DiamondIcon} to="/components/sidebar" />
        <SidebarItem title="Toggle" icon={DiamondIcon} to="/components/toggle" />
      </SidebarSection>
    </Sidebar>
  </SidebarLayout>
);

export const Route = createRootRoute({
  component: RootComponent,
});
