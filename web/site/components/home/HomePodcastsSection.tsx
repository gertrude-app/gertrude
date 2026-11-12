'use client';

import { ChevronRightIcon, DownloadIcon } from 'lucide-react';
import React from 'react';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import HomePodcastArtworkCredits from '@/components/home/HomePodcastArtworkCredits';
import HomePodcastsScreenshots from '@/components/home/HomePodcastsScreenshots';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { freeTrialDays, pricingPlans } from '@/lib/pricing';

interface HomePodcastsSectionProps {
  isDark: boolean;
}

const HomePodcastsSection: React.FC<HomePodcastsSectionProps> = ({ isDark }) => (
  <section
    id="podcasts"
    aria-labelledby="podcasts-heading"
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
        <a
          href={podcastsLearnMoreUrl}
          className={`group mb-8 flex w-fit items-center gap-0.5 font-medium transition-colors duration-700 ${
            isDark ? `text-violet-300` : `text-violet-600`
          }`}
        >
          Podcasts App
          <ChevronRightIcon className="size-5 transition-transform duration-150 group-hover:translate-x-1" />
        </a>
        <h3
          id="podcasts-heading"
          className={`text-pretty text-3xl font-semibold leading-[1.05] tracking-[-0.04em] transition-colors duration-700 sm:text-4xl lg:text-5xl ${
            isDark ? `text-stone-50` : `text-stone-950`
          }`}
        >
          Gertrude Podcasts
        </h3>
        <p
          className={`mt-4 max-w-2xl text-lg leading-7 transition-colors duration-700 sm:text-xl sm:leading-8 ${isDark ? `text-stone-300` : `text-stone-600`}`}
        >
          <strong className={`font-semibold ${isDark ? `text-white` : `text-stone-950`}`}>
            Their favorite shows. Your PIN for anything new.
          </strong>
          {` `}
          They can listen to the podcasts you’ve added anytime. Finding or adding a new
          show takes your six-digit PIN.
        </p>
        <a
          href={podcastsAppStoreUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-8 inline-block rounded-xl outline-none transition-transform duration-200 hover:-translate-y-0.5 focus-visible:ring-2 focus-visible:ring-fuchsia-300 focus-visible:ring-offset-2 focus-visible:ring-offset-stone-950"
        >
          <img
            src="/download-on-app-store.svg"
            alt="Download Gertrude Podcasts on the App Store"
            width={168}
            height={56}
            loading="lazy"
            decoding="async"
            className="h-12 w-auto invert sm:h-14"
          />
        </a>
      </div>

      <HomePodcastsScreenshots isDark={isDark}>
        <PodcastsActions isDark={isDark} />
      </HomePodcastsScreenshots>
    </HomeSectionRails>
  </section>
);

export default HomePodcastsSection;

const podcastsLearnMoreUrl = `/updates/gertrude-podcasts-launch`;
const podcastsAppStoreUrl = `https://apps.apple.com/us/app/gertrude-podcasts/id6753187429`;

const PodcastsActions: React.FC<{ isDark: boolean }> = ({ isDark }) => (
  <>
    <p
      className={`mt-7 text-center text-sm leading-6 transition-colors duration-700 sm:mt-9 ${
        isDark ? `text-stone-300` : `text-stone-600`
      }`}
    >
      Try it free for {freeTrialDays.podcasts} days, then $
      {pricingPlans.light.priceDollars} a year for your whole family.
    </p>
    <div className="mt-6 flex flex-wrap justify-center gap-3">
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
        href={podcastsAppStoreUrl}
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
  </>
);
