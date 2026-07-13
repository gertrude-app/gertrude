import React from 'react';

interface SidebarContextValue {
  close: () => void;
}

export const SidebarContext = React.createContext<SidebarContextValue>({
  close: () => undefined,
});

export const useSidebarContext = (): SidebarContextValue =>
  React.useContext(SidebarContext);
