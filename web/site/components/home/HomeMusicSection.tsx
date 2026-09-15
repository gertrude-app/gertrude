'use client';

import { ChevronRightIcon, DownloadIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import type { MusicAlbum, MusicAlbumId } from '@/lib/home-music-artwork';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import HomeMusicArtworkCredits from '@/components/home/HomeMusicArtworkCredits';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { chosenAlbumIds, musicArtwork, musicMarqueeIds } from '@/lib/home-music-artwork';

interface HomeMusicSectionProps {
  isDark: boolean;
}

const HomeMusicSection: React.FC<HomeMusicSectionProps> = ({ isDark }) => (
  <section
    aria-labelledby="music-heading"
    className={`border-t transition-colors duration-700 ${
      isDark ? `border-white/[0.06] bg-stone-950` : `border-stone-200/80 bg-white`
    }`}
  >
    <HomeSectionRails
      className={`overflow-hidden px-8 pt-28 pb-8 transition-colors duration-700 lg:px-10 lg:pt-40 lg:pb-12 ${
        isDark ? `border-white/[0.08] bg-stone-950` : `border-stone-200/80 bg-stone-50`
      }`}
    >
      <div className="max-w-4xl pl-12 sm:pl-16">
        <Link
          href="/music"
          className={`group mb-8 flex w-fit items-center gap-0.5 transition-colors duration-700 ${
            isDark ? `text-violet-300` : `text-violet-600`
          }`}
        >
          <span className="font-medium">Music App</span>
          <ChevronRightIcon className="size-5 transition-transform duration-150 group-hover:translate-x-1" />
        </Link>
        <h3
          id="music-heading"
          className={`max-w-6xl text-pretty text-3xl font-semibold leading-[1.05] tracking-[-0.04em] transition-colors duration-700 sm:text-4xl lg:text-5xl ${
            isDark ? `text-stone-50` : `text-stone-950`
          }`}
        >
          Gertrude Music
        </h3>
        <p
          className={`mt-4 max-w-2xl text-xl leading-8 transition-colors duration-700 ${
            isDark ? `text-stone-300` : `text-stone-600`
          }`}
        >
          <strong
            className={`font-semibold transition-colors duration-700 ${
              isDark ? `text-white` : `text-stone-950`
            }`}
          >
            The music you choose. Nothing else.
          </strong>
          {` `}
          Gertrude Music starts with an empty library. You approve the artists and albums;
          your child listens and makes playlists without browsing beyond those choices.
        </p>
        <a
          href={musicAppStoreUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-8 inline-block rounded-xl outline-none transition-transform duration-200 hover:-translate-y-0.5 focus-visible:ring-2 focus-visible:ring-fuchsia-300 focus-visible:ring-offset-2 focus-visible:ring-offset-stone-950"
        >
          <img
            src="/download-on-app-store.svg"
            alt="Download Gertrude Music on the App Store"
            width={168}
            height={56}
            loading="lazy"
            decoding="async"
            className="h-12 w-auto invert sm:h-14"
          />
        </a>
      </div>

      <MusicLibraryVisual isDark={isDark} />
    </HomeSectionRails>
  </section>
);

export default HomeMusicSection;

const musicAppStoreUrl = `https://apps.apple.com/us/app/gertrude-music/id6782194077`;

interface Album extends MusicAlbum {
  id: MusicAlbumId;
}

const chosenAlbums: Album[] = chosenAlbumIds.map((id) => ({
  id,
  ...musicArtwork[id],
}));

const marqueeRows: Album[][] = musicMarqueeIds.map((row) =>
  row.map((id) => ({ id, ...musicArtwork[id] })),
);

const marqueeDelays = [0, -8, -13, -19];

type MusicVisualPhase = `browsing` | `assembling` | `settled`;

interface MusicLibraryVisualProps {
  isDark: boolean;
}

const MusicLibraryVisual: React.FC<MusicLibraryVisualProps> = ({ isDark }) => {
  const visualRef = React.useRef<HTMLDivElement>(null);
  const flightLayerRef = React.useRef<HTMLDivElement>(null);
  const hasAnimatedRef = React.useRef(false);
  const [phase, setPhase] = React.useState<MusicVisualPhase>(`browsing`);

  React.useEffect(() => {
    const visual = visualRef.current;
    const flightLayer = flightLayerRef.current;
    if (!visual || !flightLayer) return;

    let cancelled = false;
    let startTimer: number | undefined;
    let cleanupTimer: number | undefined;
    const animations: Animation[] = [];
    const liftedSources: HTMLElement[] = [];

    const assembleLibrary = (): void => {
      if (cancelled) return;

      const visualBounds = visual.getBoundingClientRect();
      const flights = chosenAlbums.flatMap((album, index) => {
        const target = visual.querySelector<HTMLElement>(
          `[data-library-target="${album.id}"]`,
        );
        if (!target || target.offsetParent === null) return [];

        const targetBounds = target.getBoundingClientRect();
        const sources = Array.from(
          visual.querySelectorAll<HTMLElement>(`[data-library-source="${album.id}"]`),
        );
        const source = sources
          .map((element) => ({ element, bounds: element.getBoundingClientRect() }))
          .sort(
            (left, right) =>
              visibleArea(right.bounds, visualBounds) -
              visibleArea(left.bounds, visualBounds),
          )[0];
        if (!source) return [];

        source.element.style.opacity = `0`;
        liftedSources.push(source.element);

        const image = document.createElement(`img`);
        image.src = album.src;
        image.alt = ``;
        image.setAttribute(`aria-hidden`, `true`);
        Object.assign(image.style, {
          borderRadius: `0.75rem`,
          boxShadow: `0 18px 48px rgba(0, 0, 0, 0.34)`,
          height: `${source.bounds.height}px`,
          left: `${source.bounds.left - visualBounds.left}px`,
          objectFit: `cover`,
          pointerEvents: `none`,
          position: `absolute`,
          top: `${source.bounds.top - visualBounds.top}px`,
          transformOrigin: `top left`,
          width: `${source.bounds.width}px`,
          willChange: `transform, filter, box-shadow`,
        });
        flightLayer.append(image);

        const translateX = targetBounds.left - source.bounds.left;
        const translateY = targetBounds.top - source.bounds.top;
        const scale = targetBounds.width / source.bounds.width;
        const animation = image.animate(
          [
            {
              boxShadow: `0 18px 48px rgba(0, 0, 0, 0.34)`,
              filter: `brightness(1) saturate(1)`,
              transform: `translate3d(0, 0, 0) scale(1)`,
            },
            {
              boxShadow: `0 30px 70px rgba(0, 0, 0, 0.48)`,
              filter: `brightness(1.12) saturate(1.08)`,
              offset: 0.18,
              transform: `translate3d(0, -14px, 0) scale(1.06)`,
            },
            {
              boxShadow: `0 22px 56px rgba(0, 0, 0, 0.4)`,
              filter: `brightness(1) saturate(1)`,
              transform: `translate3d(${translateX}px, ${translateY}px, 0) scale(${scale})`,
            },
          ],
          {
            delay: index * 75,
            duration: 1050,
            easing: `cubic-bezier(0.22, 1, 0.36, 1)`,
            fill: `forwards`,
          },
        );
        animations.push(animation);
        return [animation.finished.catch(() => undefined)];
      });

      setPhase(`assembling`);
      if (flights.length === 0) {
        setPhase(`settled`);
        return;
      }

      void Promise.all(flights).then(() => {
        if (cancelled) return;
        setPhase(`settled`);
        cleanupTimer = window.setTimeout(() => flightLayer.replaceChildren(), 350);
      });
    };

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting || hasAnimatedRef.current) return;
        hasAnimatedRef.current = true;
        observer.disconnect();

        if (window.matchMedia(`(prefers-reduced-motion: reduce)`).matches) {
          setPhase(`settled`);
          return;
        }

        startTimer = window.setTimeout(assembleLibrary, 300);
      },
      { threshold: 0.28 },
    );

    observer.observe(visual);
    return () => {
      cancelled = true;
      observer.disconnect();
      if (startTimer) window.clearTimeout(startTimer);
      if (cleanupTimer) window.clearTimeout(cleanupTimer);
      animations.forEach((animation) => animation.cancel());
      liftedSources.forEach((source) => source.style.removeProperty(`opacity`));
      flightLayer.replaceChildren();
    };
  }, []);

  const isRevealing = phase !== `browsing`;
  const isSettled = phase === `settled`;

  return (
    <figure
      ref={visualRef}
      className={`relative -mx-8 mt-24 grid min-h-[50rem] w-[calc(100%+4rem)] place-items-center overflow-hidden transition-colors duration-700 sm:min-h-[59rem] lg:-mx-10 lg:min-h-[67rem] lg:w-[calc(100%+5rem)] ${
        isDark ? `border-white/[0.06] bg-stone-950` : `border-stone-200 bg-stone-50`
      }`}
    >
      <figcaption className="sr-only">
        Album covers stream through an open catalog before chosen albums assemble into a
        curated music library.
      </figcaption>

      <div
        aria-hidden
        className={`pointer-events-none absolute inset-0 bg-[url('/home/dot-noise-pattern.svg')] bg-[length:1440px_1440px] bg-repeat transition-opacity duration-700 ${
          isDark ? `opacity-40` : `opacity-0`
        }`}
        style={{
          WebkitMaskImage: `linear-gradient(to bottom, transparent, black, transparent)`,
          maskImage: `linear-gradient(to bottom, transparent, black, transparent)`,
        }}
      />

      <div
        aria-hidden
        className={`absolute inset-x-0 top-14 space-y-6 transition-[opacity,filter] duration-1000 sm:top-16 sm:space-y-7 lg:top-20 lg:space-y-8 ${
          isRevealing ? `opacity-[0.14] saturate-50` : `opacity-100 saturate-100`
        }`}
      >
        {marqueeRows.map((row, rowIndex) => (
          <AlbumMarqueeRow key={rowIndex} albums={row} rowIndex={rowIndex} />
        ))}
      </div>

      <div
        aria-hidden
        className={`pointer-events-none absolute left-1/2 top-1/2 h-[78%] w-[88%] -translate-x-1/2 -translate-y-1/2 rounded-[50%] blur-3xl transition-opacity duration-1000 ${
          isRevealing
            ? isDark
              ? `bg-stone-950/90 opacity-100`
              : `bg-stone-50/90 opacity-100`
            : `opacity-0`
        }`}
      />

      <div className="relative mx-auto w-[82%] max-w-[44rem] py-20">
        <div
          className={`mb-5 text-center transition-[opacity,transform] duration-700 sm:mb-7 ${
            isRevealing ? `translate-y-0 opacity-100` : `translate-y-3 opacity-0`
          }`}
        >
          <p
            className={`text-sm font-semibold tracking-[0.16em] transition-colors duration-700 ${
              isDark ? `text-violet-300` : `text-violet-600`
            }`}
          >
            Curated Music Library
          </p>
        </div>

        <div className="grid grid-cols-2 gap-x-3 gap-y-5 sm:grid-cols-3 sm:gap-x-5 sm:gap-y-7">
          {chosenAlbums.map((album, index) => (
            <figure key={album.id} className={index >= 4 ? `hidden sm:block` : undefined}>
              <div
                data-library-target={album.id}
                className={`relative aspect-square overflow-hidden rounded-xl transition-shadow duration-300 ${
                  isSettled
                    ? `shadow-[0_22px_56px_rgba(0,0,0,0.4)] ring-1 ring-inset ring-white/15`
                    : ``
                }`}
              >
                <img
                  src={album.src}
                  alt={`${album.title} by ${album.artist}`}
                  width={504}
                  height={504}
                  loading="lazy"
                  decoding="async"
                  className={`size-full object-cover transition-opacity duration-300 ${
                    isSettled ? `opacity-100` : `opacity-0`
                  }`}
                />
              </div>
              <figcaption
                className={`mt-2.5 min-w-0 transition-[opacity,transform] duration-500 ${
                  isSettled ? `translate-y-0 opacity-100` : `translate-y-2 opacity-0`
                }`}
              >
                <p
                  className={`truncate text-xs font-semibold transition-colors duration-700 sm:text-sm ${
                    isDark ? `text-white` : `text-stone-950`
                  }`}
                >
                  {album.title}
                </p>
                <p
                  className={`mt-0.5 truncate text-[10px] transition-colors duration-700 sm:text-xs ${
                    isDark ? `text-stone-400` : `text-stone-500`
                  }`}
                >
                  {album.artist}
                </p>
              </figcaption>
            </figure>
          ))}
        </div>

        <p
          className={`mt-7 text-center text-sm leading-6 transition-[color,opacity,transform] delay-150 duration-700 sm:mt-9 sm:text-base ${
            isDark ? `text-stone-300` : `text-stone-600`
          } ${isSettled ? `translate-y-0 opacity-100` : `translate-y-3 opacity-0`}`}
        >
          Chosen by you. The only music that can play.
        </p>
        <div
          aria-hidden={!isSettled}
          className={`mt-6 flex flex-wrap justify-center gap-3 transition-[opacity,transform] delay-300 duration-700 ${
            isSettled
              ? `translate-y-0 opacity-100`
              : `pointer-events-none translate-y-3 opacity-0`
          }`}
        >
          <HomeButtonLink
            href="/music"
            size="hero"
            variant="secondary"
            inverted={isDark}
            tabIndex={isSettled ? undefined : -1}
          >
            Learn more
            <ChevronRightIcon className="size-4" />
          </HomeButtonLink>
          <HomeButtonLink
            href={musicAppStoreUrl}
            target="_blank"
            rel="noopener noreferrer"
            size="hero"
            variant="primary"
            inverted={isDark}
            tabIndex={isSettled ? undefined : -1}
          >
            Download
            <DownloadIcon className="size-4" />
          </HomeButtonLink>
        </div>
        <div
          inert={!isSettled}
          className={`relative z-10 transition-opacity delay-300 duration-700 ${
            isSettled ? `opacity-100` : `opacity-0`
          }`}
        >
          <HomeMusicArtworkCredits isDark={isDark} />
        </div>
      </div>

      <div
        ref={flightLayerRef}
        aria-hidden
        className="pointer-events-none absolute inset-0 z-20"
      />

      <div
        aria-hidden
        className={`pointer-events-none absolute inset-y-0 left-0 w-20 bg-gradient-to-r to-transparent sm:w-32 ${
          isDark ? `from-stone-950` : `from-stone-50`
        }`}
      />
      <div
        aria-hidden
        className={`pointer-events-none absolute inset-y-0 right-0 w-20 bg-gradient-to-l to-transparent sm:w-32 ${
          isDark ? `from-stone-950` : `from-stone-50`
        }`}
      />
    </figure>
  );
};

interface AlbumMarqueeRowProps {
  albums: Album[];
  rowIndex: number;
}

const AlbumMarqueeRow: React.FC<AlbumMarqueeRowProps> = ({ albums, rowIndex }) => (
  <div className="overflow-hidden">
    <div
      className={`home-music-marquee-track ${
        rowIndex % 2 === 1 ? `home-music-marquee-track-reverse` : ``
      }`}
      style={{
        animationDelay: `${marqueeDelays[rowIndex] ?? 0}s`,
        animationDuration: `${34 + rowIndex * 7}s`,
      }}
    >
      {[0, 1].map((copy) => (
        <div
          key={copy}
          className="flex shrink-0 gap-3 pr-3 sm:gap-4 sm:pr-4 lg:gap-5 lg:pr-5"
        >
          {albums.map((album, index) => (
            <div
              key={`${copy}-${index}-${album.id}`}
              data-library-source={album.id}
              className="aspect-square w-28 shrink-0 overflow-hidden rounded-xl shadow-[0_18px_48px_rgba(0,0,0,0.28)] ring-1 ring-inset ring-white/10 xs:w-32 sm:w-36 lg:w-40 xl:w-44"
            >
              <img
                src={album.src}
                alt=""
                width={504}
                height={504}
                loading="lazy"
                decoding="async"
                className="size-full object-cover"
              />
            </div>
          ))}
        </div>
      ))}
    </div>
  </div>
);

const visibleArea = (bounds: DOMRect, container: DOMRect): number => {
  const width = Math.max(
    0,
    Math.min(bounds.right, container.right) - Math.max(bounds.left, container.left),
  );
  const height = Math.max(
    0,
    Math.min(bounds.bottom, container.bottom) - Math.max(bounds.top, container.top),
  );
  return width * height;
};
