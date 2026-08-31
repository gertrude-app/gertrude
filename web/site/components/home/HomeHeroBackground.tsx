'use client';

import React from 'react';

const HomeHeroBackground: React.FC = () => {
  const [isScrolled, setIsScrolled] = React.useState(false);

  React.useEffect(() => {
    const updateScrollState = (): void => setIsScrolled(window.scrollY > 8);
    updateScrollState();
    window.addEventListener(`scroll`, updateScrollState, { passive: true });
    return () => window.removeEventListener(`scroll`, updateScrollState);
  }, []);

  return (
    <div
      aria-hidden
      className={`home-hero-background pointer-events-none absolute inset-y-0 -z-10 overflow-hidden transition-[left,right] duration-300 ease-out motion-reduce:transition-none ${
        isScrolled ? `home-hero-background-scrolled ring-1 ring-inset ring-black/5` : ``
      }`}
    >
      <div
        className="absolute inset-y-0 left-1/2 w-screen -translate-x-1/2 bg-cover bg-bottom"
        style={{
          backgroundImage: `linear-gradient(to bottom, rgb(255 255 255) 0%, rgb(255 255 255) 8%, rgb(255 255 255 / 0) 28%), url('/home/hero-background.png')`,
        }}
      />
    </div>
  );
};

export default HomeHeroBackground;
