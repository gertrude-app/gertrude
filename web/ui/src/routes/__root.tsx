import { Outlet, createRootRoute } from '@tanstack/react-router';
import { DiamondIcon } from 'lucide-react';
import React from 'react';
import Toaster from '#/components/ui/Toaster';
import Sidebar from '#/components/ui/sidebar/Sidebar';
import SidebarItem from '#/components/ui/sidebar/SidebarItem';
import SidebarLayout from '#/components/ui/sidebar/SidebarLayout';
import SidebarSection from '#/components/ui/sidebar/SidebarSection';
import '../styles.css';

const RootComponent: React.FC = () => (
  <>
    <SidebarLayout content={<Outlet />}>
      <Sidebar logoUrl="/gertrude-ui-logo.svg" logoWidth={60}>
        <SidebarSection title="Components">
          <SidebarItem title="Badge" icon={DiamondIcon} href="/components/badge" />
          <SidebarItem title="Banner" icon={DiamondIcon} href="/components/banner" />
          <SidebarItem title="Button" icon={DiamondIcon} href="/components/button" />
          <SidebarItem title="Checkbox" icon={DiamondIcon} href="/components/checkbox" />
          <SidebarItem
            title="Confirmation Dialog"
            icon={DiamondIcon}
            href="/components/confirmation-dialog"
          />
          <SidebarItem
            title="DateTimePicker"
            icon={DiamondIcon}
            href="/components/date-time-picker"
          />
          <SidebarItem
            title="Dropdown Menu"
            icon={DiamondIcon}
            href="/components/dropdown-menu"
          />
          <SidebarItem title="Input" icon={DiamondIcon} href="/components/input" />
          <SidebarItem
            title="LoadingDots"
            icon={DiamondIcon}
            href="/components/loading-dots"
          />
          <SidebarItem title="Modal" icon={DiamondIcon} href="/components/modal" />
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
          <SidebarItem
            title="Slide Over"
            icon={DiamondIcon}
            href="/components/slide-over"
          />
          <SidebarItem title="Textarea" icon={DiamondIcon} href="/components/textarea" />
          <SidebarItem title="Toast" icon={DiamondIcon} href="/components/toast" />
          <SidebarItem title="Toggle" icon={DiamondIcon} href="/components/toggle" />
          <SidebarItem title="Tooltip" icon={DiamondIcon} href="/components/tooltip" />
        </SidebarSection>
      </Sidebar>
    </SidebarLayout>
    <Toaster />
  </>
);

export const Route = createRootRoute({
  component: RootComponent,
});
