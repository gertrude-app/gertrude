import React, { useState } from 'react';
import { Chrome } from '@dash/components';
import type { DecoratorFn } from '@storybook/react';

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
      onLogout={() => {}}
      sidebarCollapsed={collapsed}
      onToggleSidebarCollapsed={() => setCollapsed(!collapsed)}
    >
      {children}
    </Chrome>
  );
};

export const withStatefulChrome: DecoratorFn = (Story) => (
  <StatefulChrome>
    <Story />
  </StatefulChrome>
);

export default StatefulChrome;
