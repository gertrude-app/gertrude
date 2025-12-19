import { Chrome } from '@dash/components';
import React, { useState } from 'react';
import type { Decorator } from '@storybook/react';

const StatefulChrome: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [open, setOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  return (
    <Chrome
      urlPath=""
      mobileSidebarOpen={open}
      onMobileHamburgerClick={() => setOpen(true)}
      onMobileSidebarClose={() => setOpen(false)}
      onInternalLinkClick={() => setOpen(false)}
      sidebarCollapsed={collapsed}
      onToggleSidebarCollapsed={() => setCollapsed(!collapsed)}
    >
      {children}
    </Chrome>
  );
};

export const withStatefulChrome: Decorator = (Story) => (
  <StatefulChrome>
    <Story />
  </StatefulChrome>
);

export default StatefulChrome;
