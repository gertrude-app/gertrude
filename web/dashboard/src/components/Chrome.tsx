import React, { useState } from 'react';
import Chrome from '@shared/dashboard/Chrome';

interface Props {
  children: React.ReactNode;
}

const ChromeContainer: React.FC<Props> = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  return (
    <Chrome
      children={children}
      mobileSidebarOpen={sidebarOpen}
      setMobileSidebarOpen={setSidebarOpen}
      urlPath={location.pathname}
      onLogout={() => {}}
      sidebarCollapsed={collapsed}
      setSidebarCollapsed={setCollapsed}
    />
  );
};

export default ChromeContainer;
