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
    <Sidebar logoUrl="/gertrude-ui-logo.svg" logoWidth={60}>
      <SidebarSection title="Components">
        <SidebarItem title="Badge" icon={DiamondIcon} href="/components/badge" />
        <SidebarItem title="Button" icon={DiamondIcon} href="/components/button" />
        <SidebarItem title="Checkbox" icon={DiamondIcon} href="/components/checkbox" />
        <SidebarItem
          title="Dropdown Menu"
          icon={DiamondIcon}
          href="/components/dropdown-menu"
        />
        <SidebarItem title="Form" icon={DiamondIcon} href="/components/form" />
        <SidebarItem title="Input" icon={DiamondIcon} href="/components/input" />
        <SidebarItem
          title="Page Heading"
          icon={DiamondIcon}
          href="/components/page-heading"
        />
        <SidebarItem
          title="Radio Group"
          icon={DiamondIcon}
          href="/components/radio-group"
        />
        <SidebarItem title="Select" icon={DiamondIcon} href="/components/select" />
        <SidebarItem title="Sidebar" icon={DiamondIcon} href="/components/sidebar" />
        <SidebarItem title="Textarea" icon={DiamondIcon} href="/components/textarea" />
        <SidebarItem title="Toggle" icon={DiamondIcon} href="/components/toggle" />
      </SidebarSection>
    </Sidebar>
  </SidebarLayout>
);

export const Route = createRootRoute({
  component: RootComponent,
});
