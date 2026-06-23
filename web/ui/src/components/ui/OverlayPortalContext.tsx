import React from 'react';

const OverlayPortalContext = React.createContext<HTMLElement | null>(null);

interface OverlayPortalProviderProps {
  container: HTMLElement | null;
  children: React.ReactNode;
}

export const OverlayPortalProvider: React.FC<OverlayPortalProviderProps> = ({
  container,
  children,
}) => (
  <OverlayPortalContext.Provider value={container}>
    {children}
  </OverlayPortalContext.Provider>
);

export const useOverlayPortalContainer = (): HTMLElement | null =>
  React.useContext(OverlayPortalContext);
