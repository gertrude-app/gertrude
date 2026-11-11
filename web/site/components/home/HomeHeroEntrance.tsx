'use client';

import React from 'react';

const HeroEntranceContext = React.createContext(false);

interface HomeHeroEntranceProps {
  children: React.ReactNode;
  className: string;
}

const HomeHeroEntrance: React.FC<HomeHeroEntranceProps> = ({ children, className }) => {
  const [ready, setReady] = React.useState(false);

  React.useLayoutEffect(() => setReady(true), []);

  return (
    <HeroEntranceContext.Provider value={ready}>
      <section className={className} data-entrance-ready={ready}>
        {children}
      </section>
    </HeroEntranceContext.Provider>
  );
};

export function useHeroEntranceReady(): boolean {
  return React.useContext(HeroEntranceContext);
}

export default HomeHeroEntrance;
