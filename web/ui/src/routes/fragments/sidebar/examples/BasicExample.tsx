import Sidebar from '#/components/ui/fragments/sidebar/Sidebar';
import SidebarItem from '#/components/ui/fragments/sidebar/SidebarItem';
import SidebarLayout from '#/components/ui/fragments/sidebar/SidebarLayout';
import SidebarSection from '#/components/ui/fragments/sidebar/SidebarSection';
import SidebarSubItem from '#/components/ui/fragments/sidebar/SidebarSubItem';
import {
  BookOpenTextIcon,
  HomeIcon,
  KeyIcon,
  LifeBuoyIcon,
  MonitorSmartphoneIcon,
  UsersIcon,
} from 'lucide-react';
import React from 'react';

const BasicExample: React.FC = () => {
  return (
    <SidebarLayout content={<div>Hello, world!</div>}>
      <Sidebar logoUrl="/gertrude-ui-logo.svg">
        <SidebarSection title="Platform">
          <SidebarItem title="Dashboard" icon={HomeIcon} to="#" />
          <SidebarItem title="Children" icon={UsersIcon}>
            <SidebarSubItem title="Little Jimmy" />
            <SidebarSubItem title="Sally" />
            <SidebarSubItem title="Franny" />
            <SidebarSubItem title="John Doe" />
          </SidebarItem>
          <SidebarItem title="Devices" icon={MonitorSmartphoneIcon}>
            <SidebarSubItem title="Family iPad" />
            <SidebarSubItem title="John's MacBook Pro" />
            <SidebarSubItem title="Sally's iPhone" />
            <SidebarSubItem title="Family Computer" />
            <SidebarSubItem title="School Computer" />
            <SidebarSubItem title="Franny's School Laptop" />
          </SidebarItem>
          <SidebarItem title="Keychains" icon={KeyIcon} to="#" />
        </SidebarSection>
        <SidebarSection title="Help">
          <SidebarItem title="Docs" icon={BookOpenTextIcon} to="#" />
          <SidebarItem title="Support" icon={LifeBuoyIcon} to="#" />
        </SidebarSection>
      </Sidebar>
    </SidebarLayout>
  );
};

export default BasicExample;
