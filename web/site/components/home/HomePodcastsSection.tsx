'use client';

import { ChevronRightIcon, DownloadIcon } from 'lucide-react';
import React from 'react';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import HomePodcastArtworkCredits from '@/components/home/HomePodcastArtworkCredits';
import HomePodcastsVisual from '@/components/home/HomePodcastsVisual';
import HomeSectionRails from '@/components/home/HomeSectionRails';

const HomePodcastsSection: React.FC<{ isDark: boolean }> = ({ isDark }) => (
  <section
    id="podcasts"
    aria-labelledby="podcasts-heading"
    className={`border-t transition-colors duration-700 ${
      isDark ? `border-white/[0.06] bg-stone-950` : `border-stone-200/80 bg-white`
    }`}
  >
    <HomeSectionRails
      className={`overflow-hidden px-8 py-28 transition-colors duration-700 lg:px-10 lg:py-40 ${
        isDark ? `border-white/[0.08] bg-stone-950` : `border-stone-200/80 bg-stone-50`
      }`}
    >
      <div className="mx-auto max-w-4xl text-center">
        <a
          href={podcastsLearnMoreUrl}
          className={`group mx-auto mb-8 flex w-fit items-center gap-0.5 font-medium ${
            isDark ? `text-violet-300` : `text-violet-600`
          }`}
        >
          Podcasts App
          <ChevronRightIcon className="size-5 transition-transform duration-150 group-hover:translate-x-1" />
        </a>
        <h3
          id="podcasts-heading"
          className={`text-pretty text-3xl font-semibold leading-[1.05] tracking-[-0.04em] sm:text-4xl lg:text-5xl ${
            isDark ? `text-stone-50` : `text-stone-950`
          }`}
        >
          Gertrude Podcasts
        </h3>
        <p
          className={`mx-auto mt-4 max-w-2xl text-xl leading-8 ${isDark ? `text-stone-300` : `text-stone-600`}`}
        >
          <strong className={`font-semibold ${isDark ? `text-white` : `text-stone-950`}`}>
            Their favorite shows. Your PIN for anything new.
          </strong>
          {` `}
          Listen freely to the podcasts you’ve added. Searching for new shows or adding
          another podcast requires your six-digit PIN.
        </p>
      </div>

      <HomePodcastsVisual isDark={isDark} />

      <div className="mt-10 flex flex-wrap justify-center gap-3">
        <HomeButtonLink
          href={podcastsLearnMoreUrl}
          size="hero"
          variant="secondary"
          inverted={isDark}
        >
          Learn more
          <ChevronRightIcon className="size-4" />
        </HomeButtonLink>
        <HomeButtonLink
          href="https://apps.apple.com/us/app/gertrude-podcasts/id6753187429"
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
      <HomePodcastArtworkCredits isDark={isDark} />
    </HomeSectionRails>
  </section>
);

export default HomePodcastsSection;

const podcastsLearnMoreUrl = `/updates/gertrude-podcasts-launch`;
