'use client';

import React from 'react';
import HomeFeatureCaption from '@/components/home/HomeFeatureCaption';
import { useIntersectionVisibility } from '@/lib/hooks';

interface AppScreenshot {
  id: string;
  src: string;
  srcSet?: string;
  alt: string;
  title: string;
  description: string;
}

interface HomeAppScreenshotsProps {
  isDark: boolean;
  label: string;
  screens: AppScreenshot[];
  backgroundImage: string;
  children: React.ReactNode;
}

const HomeAppScreenshots: React.FC<HomeAppScreenshotsProps> = ({
  isDark,
  label,
  screens,
  backgroundImage,
  children,
}) => {
  const galleryRef = React.useRef<HTMLDivElement>(null);
  const isVisible = useIntersectionVisibility(galleryRef, 0.15);

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
      <div className="pb-10">
        <div
          ref={galleryRef}
          role="region"
          aria-label={label}
          tabIndex={0}
          className="-mx-8 snap-x snap-mandatory overflow-x-auto overscroll-x-contain px-8 pb-4 outline-none scroll-px-8 focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-violet-400 sm:px-12 sm:scroll-px-12 xl:mx-0 xl:overflow-visible xl:px-16 xl:scroll-px-16"
        >
          <ul className="flex w-max items-start gap-6 sm:gap-8 xl:grid xl:w-auto xl:grid-cols-3 xl:gap-12">
            {screens.map((screen, index) => (
              <li
                key={screen.id}
                className="w-[min(76vw,20rem)] min-w-0 shrink-0 snap-start xl:w-auto"
              >
                <figure
                  className={`home-js-reveal transition-[opacity,transform] duration-700 ease-out motion-reduce:translate-y-0 motion-reduce:opacity-100 motion-reduce:transition-none ${
                    isVisible ? `translate-y-0 opacity-100` : `translate-y-8 opacity-0`
                  }`}
                  style={{ transitionDelay: `${index * 150}ms` }}
                >
                  <img
                    src={screen.src}
                    srcSet={screen.srcSet}
                    sizes="(min-width: 1280px) 320px, (min-width: 422px) 320px, 76vw"
                    alt={screen.alt}
                    width={1350}
                    height={2760}
                    loading="lazy"
                    decoding="async"
                    className="h-auto w-full"
                  />
                  <figcaption>
                    <HomeFeatureCaption
                      title={screen.title}
                      description={screen.description}
                      backgroundImage={backgroundImage}
                      backgroundOpacity={0.15}
                      inverted={isDark}
                    />
                  </figcaption>
                </figure>
              </li>
            ))}
          </ul>
        </div>
        <p
          className={`mt-4 text-center text-xs xl:hidden ${
            isDark ? `text-white` : `text-stone-700`
          }`}
        >
          Swipe to see all three screens
        </p>
      </div>
      <div className="mx-auto mt-12 max-w-3xl pb-8 sm:mt-16">{children}</div>
    </div>
  );
};

export default HomeAppScreenshots;
