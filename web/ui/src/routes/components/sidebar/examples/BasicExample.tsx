import {
  BookOpenTextIcon,
  HomeIcon,
  KeyIcon,
  LifeBuoyIcon,
  MonitorSmartphoneIcon,
  UsersIcon,
} from 'lucide-react';
import React from 'react';
import Sidebar from '#/components/ui/sidebar/Sidebar';
import SidebarItem from '#/components/ui/sidebar/SidebarItem';
import SidebarLayout from '#/components/ui/sidebar/SidebarLayout';
import SidebarSection from '#/components/ui/sidebar/SidebarSection';

const BasicExample: React.FC = () => (
  <SidebarLayout content={<div>Hello, world!</div>}>
    <Sidebar logoUrl="/gertrude-ui-logo.svg" logoWidth={60}>
      <SidebarSection title="Platform">
        <SidebarItem title="Dashboard" icon={HomeIcon} href="#" />
        <SidebarItem title="Children" icon={UsersIcon} href="#" />
        <SidebarItem title="Devices" icon={MonitorSmartphoneIcon} href="#" />
        <SidebarItem title="Keychains" icon={KeyIcon} href="#" />
      </SidebarSection>
      <SidebarSection title="Help">
        <SidebarItem title="Docs" icon={BookOpenTextIcon} href="#" />
        <SidebarItem title="Support" icon={LifeBuoyIcon} href="#" />
      </SidebarSection>
    </Sidebar>
  </SidebarLayout>
);

export default BasicExample;
