'use client';

import { ChevronRightIcon, DownloadIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import HomeMusicArtworkCredits from '@/components/home/HomeMusicArtworkCredits';
import HomeMusicScreenshots from '@/components/home/HomeMusicScreenshots';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { freeTrialDays, pricingPlans } from '@/lib/pricing';

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
      className={`overflow-hidden px-8 pt-20 pb-8 transition-colors duration-700 sm:pt-28 lg:px-10 lg:pt-40 lg:pb-12 ${
        isDark ? `border-white/[0.08] bg-stone-950` : `border-stone-200/80 bg-stone-50`
      }`}
    >
      <div className="max-w-4xl sm:pl-6 lg:pl-16">
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
          className={`mt-4 max-w-2xl text-lg leading-7 transition-colors duration-700 sm:text-xl sm:leading-8 ${
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
          Gertrude Music starts with an empty library. You add the artists and albums, and
          they get a beautiful, full-featured music app, with no searching beyond what
          you’ve chosen.
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

      <HomeMusicScreenshots isDark={isDark}>
        <MusicActions isDark={isDark} />
      </HomeMusicScreenshots>
    </HomeSectionRails>
  </section>
);

export default HomeMusicSection;

const musicAppStoreUrl = `https://apps.apple.com/us/app/gertrude-music/id6782194077`;

const MusicActions: React.FC<{ isDark: boolean }> = ({ isDark }) => (
  <>
    <p
      className={`mt-7 text-center text-sm leading-6 transition-colors delay-150 duration-700 sm:mt-9 sm:text-base ${
        isDark ? `text-stone-300` : `text-stone-600`
      }`}
    >
      Try it free for {freeTrialDays.music} days, then ${pricingPlans.medium.priceDollars}
      {` `}a month for your whole family.
    </p>
    <div className="mt-6 flex flex-wrap justify-center gap-3">
      <HomeButtonLink href="/music" size="hero" variant="secondary" inverted={isDark}>
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
      >
        Download
        <DownloadIcon className="size-4" />
      </HomeButtonLink>
    </div>
    <div className="relative z-10">
      <HomeMusicArtworkCredits isDark={isDark} />
    </div>
  </>
);
