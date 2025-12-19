import { Chrome } from '@dash/components';
import React, { useState } from 'react';
import Current from '../environment';
import useWindowWidth from '../hooks/window-width';

interface Props {
  children: React.ReactNode;
}

const ChromeContainer: React.FC<Props> = ({ children }) => {
  const windowWidth = useWindowWidth();
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);
  const [desktopSidebarCollapsed, setDesktopSidebarCollapsed] = useState(
    Current.localStorage.getItem(`desktop_sidebar_collapsed`) === `true`,
  );

  return (
    <Chrome
      children={children}
      mobileSidebarOpen={mobileSidebarOpen}
      urlPath={location.pathname}
      sidebarCollapsed={desktopSidebarCollapsed}
      onMobileHamburgerClick={() => setMobileSidebarOpen(true)}
      onMobileSidebarClose={() => setMobileSidebarOpen(false)}
      onToggleSidebarCollapsed={() => {
        const toggled = !desktopSidebarCollapsed;
        Current.localStorage.setItem(`desktop_sidebar_collapsed`, `${toggled}`);
        setDesktopSidebarCollapsed(toggled);
      }}
      onInternalLinkClick={() => setMobileSidebarOpen(false)}
      usingMobileView={windowWidth < 768}
    />
  );
};

export default ChromeContainer;
