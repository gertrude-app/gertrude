import React from 'react';
import SidebarLink from './SidebarLink';

const Sidebar: React.FC = () => (
  <nav className="w-52 flex flex-col p-4 bg-gradient-to-b from-violet-50 to-fuchsia-50 gap-2 shrink-0 fixed h-screen">
    <SidebarLink href="/">Overview</SidebarLink>
    <SidebarLink href="/admins">Admins</SidebarLink>
  </nav>
);

export default Sidebar;
