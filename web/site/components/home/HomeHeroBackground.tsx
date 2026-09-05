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
      <div className="absolute inset-y-0 left-1/2 w-screen -translate-x-1/2">
        <img
          src="/home/hero-background.webp"
          srcSet="/home/hero-background-1280.webp 1280w, /home/hero-background-1600.webp 1600w, /home/hero-background-1920.webp 1920w, /home/hero-background-2560.webp 2560w, /home/hero-background.webp 3024w"
          sizes="(orientation: portrait) 150vh, 100vw"
          alt=""
          width={3024}
          height={2016}
          loading="eager"
          decoding="async"
          fetchPriority="high"
          className="absolute inset-0 size-full object-cover object-bottom"
        />
        <div
          className="absolute inset-0"
          style={{
            backgroundImage: `linear-gradient(to bottom, rgb(255 255 255) 0%, rgb(255 255 255) 8%, rgb(255 255 255 / 0) 28%)`,
          }}
        />
      </div>
    </div>
  );
};

export default HomeHeroBackground;
