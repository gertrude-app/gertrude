'use client';

import React from 'react';
import HomeFeatureCaption from '@/components/home/HomeFeatureCaption';
import { useIntersectionVisibility } from '@/lib/hooks';

const backgroundImage = `/home/music-screenshots/background.webp`;

const devices = [
  {
    id: `duo`,
    title: `A full-featured player.`,
    description: `Shuffle, repeat, and keep the music going with Infinite Play.`,
    alt: `Gertrude Music playing Tale of Two Dragons by Calan on the outer screen of an iPhone Duo`,
    width: 900,
    height: 1255,
    src: `/home/music-screenshots/duo-900.webp`,
    srcSet: `/home/music-screenshots/duo-480.webp 480w, /home/music-screenshots/duo-900.webp 900w`,
    sizes: `(min-width: 1280px) 264px, (min-width: 640px) 23vw, 30vw`,
    position: `left-0 bottom-0 z-10 w-[30%] sm:left-[3%] sm:w-[23%]`,
    hidden: `-translate-x-6 translate-y-10`,
    delay: 220,
  },
  {
    id: `ipad`,
    title: `Rich artist pages.`,
    description: `Top songs and albums for every artist you add, on iPhone or iPad.`,
    alt: `Gertrude Music on iPad showing the Ben Wendel artist page with top songs and releases`,
    width: 2000,
    height: 1534,
    src: `/home/music-screenshots/ipad-2000.webp`,
    srcSet: `/home/music-screenshots/ipad-1200.webp 1200w, /home/music-screenshots/ipad-2000.webp 2000w`,
    sizes: `(min-width: 1280px) 806px, (min-width: 640px) 70vw, 82vw`,
    position: `left-[9%] top-0 w-[82%] sm:left-[15%] sm:w-[70%]`,
    hidden: `translate-y-10`,
    delay: 0,
  },
  {
    id: `iphone`,
    title: `Their whole collection, at a glance.`,
    description: `Every artist and album you’ve added, beautifully organized and ready to play.`,
    alt: `Gertrude Music library on iPhone with albums, an artist, and a Road Trip playlist`,
    width: 810,
    height: 1656,
    src: `/home/music-screenshots/iphone-810.webp`,
    srcSet: `/home/music-screenshots/iphone-420.webp 420w, /home/music-screenshots/iphone-810.webp 810w`,
    sizes: `(min-width: 1280px) 218px, (min-width: 640px) 19vw, 25vw`,
    position: `right-0 bottom-0 z-10 w-[25%] sm:right-[4%] sm:w-[19%]`,
    hidden: `translate-x-6 translate-y-10`,
    delay: 380,
  },
];

const HomeMusicScreenshots: React.FC<{
  isDark: boolean;
  children: React.ReactNode;
}> = ({ isDark, children }) => {
  const stageRef = React.useRef<HTMLDivElement>(null);
  const isVisible = useIntersectionVisibility(stageRef, 0.2);
  const reveal = (hidden: string): string =>
    `home-js-reveal transition-[opacity,transform] duration-700 ease-out motion-reduce:translate-x-0 motion-reduce:translate-y-0 motion-reduce:opacity-100 motion-reduce:transition-none ${
      isVisible ? `translate-x-0 translate-y-0 opacity-100` : `${hidden} opacity-0`
    }`;

  return (
    <div
      className={`relative isolate -mx-8 -mb-8 mt-16 px-8 pb-8 transition-colors duration-700 lg:-mx-10 lg:-mb-12 lg:mt-24 lg:px-10 lg:pb-12 ${
        isDark ? `bg-stone-950` : `bg-stone-50`
      }`}
    >
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 -z-10 bg-cover bg-center bg-no-repeat"
        style={{
          backgroundImage: `url('${backgroundImage}')`,
          WebkitMaskImage: `linear-gradient(to bottom, transparent 0%, transparent 15%, rgba(0, 0, 0, 0.05) 100%)`,
          maskImage: `linear-gradient(to bottom, transparent 0%, transparent 15%, rgba(0, 0, 0, 0.05) 100%)`,
        }}
      />
      <div
        ref={stageRef}
        role="group"
        aria-label="Gertrude Music on iPhone Duo, iPad, and iPhone"
        className="relative -mx-6 aspect-[3/2] w-[calc(100%+3rem)] max-w-6xl sm:mx-auto sm:aspect-[9/5] sm:w-full"
      >
        {devices.map((device) => (
          <img
            key={device.id}
            src={device.src}
            srcSet={device.srcSet}
            sizes={device.sizes}
            alt={device.alt}
            width={device.width}
            height={device.height}
            loading="lazy"
            decoding="async"
            className={`absolute h-auto ${device.position} ${
              device.id === `ipad` ? `` : `drop-shadow-[0_24px_36px_rgba(0,0,0,0.35)]`
            } ${reveal(device.hidden)}`}
            style={{ transitionDelay: `${device.delay}ms` }}
          />
        ))}
      </div>
      <ul className="mx-auto mt-10 grid max-w-6xl gap-8 sm:mt-14 lg:grid-cols-3 lg:gap-10">
        {devices.map((device) => (
          <li
            key={device.id}
            className={reveal(`translate-y-4`)}
            style={{ transitionDelay: `${device.delay + 300}ms` }}
          >
            <HomeFeatureCaption
              title={device.title}
              description={device.description}
              backgroundImage={backgroundImage}
              backgroundOpacity={0.15}
              inverted={isDark}
            />
          </li>
        ))}
      </ul>
      <div className="mx-auto mt-12 max-w-3xl pb-8 sm:mt-16">{children}</div>
    </div>
  );
};

export default HomeMusicScreenshots;
