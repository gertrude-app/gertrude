import { ArrowRightIcon } from 'lucide-react';
import Link from 'next/link';
import type { NextPage } from 'next';
import GertrudeForIOS from '@/components/GertrudeForIOS';
import GertrudeForMac from '@/components/GertrudeForMac';
import HiImJared from '@/components/HiImJared';
import PodcastsBlock from '@/components/PodcastsBlock';
import ToolsForSafetyBlock from '@/components/ToolsForSafetyBlock';
import { createMetadata } from '@/lib/seo';

export const metadata = createMetadata(
  `Gertrude | Parental Controls for Mac, iPhone, and iPad`,
  `Gertrude offers comprehensive parental controls for Mac, iPhone, and iPad. Block porn, filter websites, monitor screenshots, and protect your kids online with easy-to-use tools designed for families.`,
);

const HomePage: NextPage = () => (
  <main>
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(JSON_LD) }}
    />
    <ToolsForSafetyBlock />
    <GertrudeForMac />
    <GertrudeForIOS />
    <PodcastsBlock />
    <section className="relative overflow-hidden bg-violet-900 px-6 py-10 sm:py-12">
      <div className="[background:radial-gradient(#e879f933,transparent_70%)] pointer-events-none absolute -right-32 -top-32 h-80 w-80" />
      <div className="[background:radial-gradient(#a78bfa2e,transparent_70%)] pointer-events-none absolute -bottom-32 -left-32 h-80 w-80" />
      <div className="relative mx-auto flex max-w-3xl flex-col items-center justify-center gap-x-6 gap-y-5 sm:flex-row">
        <p className="text-white text-lg sm:text-xl font-semibold text-center sm:text-left">
          One account, your whole family, every device.
        </p>
        <Link
          href="/pricing"
          className="group inline-flex items-center gap-2 rounded-full bg-gradient-to-r from-violet-500 to-fuchsia-500 px-6 py-3 font-semibold text-white shadow-lg shadow-fuchsia-500/30 transition-transform hover:scale-105 whitespace-nowrap"
        >
          See all plans
          <ArrowRightIcon className="size-5 transition-transform group-hover:translate-x-0.5" />
        </Link>
      </div>
    </section>
    <HiImJared />
  </main>
);

export default HomePage;

const JSON_LD = {
  '@context': `https://schema.org`,
  '@graph': [
    {
      '@type': `Organization`,
      '@id': `https://gertrude.app/#organization`,
      name: `Gertrude`,
      url: `https://gertrude.app`,
      logo: {
        '@type': `ImageObject`,
        url: `https://gertrude.app/gertrude-icon.png`,
      },
      sameAs: [`https://github.com/gertrude-app`],
    },
    {
      '@type': `WebSite`,
      '@id': `https://gertrude.app/#website`,
      url: `https://gertrude.app`,
      name: `Gertrude`,
      publisher: { '@id': `https://gertrude.app/#organization` },
    },
    {
      '@type': `SoftwareApplication`,
      name: `Gertrude for Mac`,
      operatingSystem: `macOS`,
      applicationCategory: `UtilitiesApplication`,
      description: `Comprehensive web filtering and activity monitoring. The most powerful parental controls ever built for macOS.`,
      offers: {
        '@type': `Offer`,
        price: `10.00`,
        priceCurrency: `USD`,
        priceValidUntil: `2026-12-31`,
      },
      aggregateRating: {
        '@type': `AggregateRating`,
        ratingValue: `5`,
        ratingCount: `50`,
      },
    },
    {
      '@type': `SoftwareApplication`,
      name: `Gertrude Blocker`,
      operatingSystem: `iOS`,
      applicationCategory: `UtilitiesApplication`,
      description: `Block GIF searches, spotlight image search, and other Screen Time loopholes on iPhone and iPad.`,
      offers: {
        '@type': `Offer`,
        price: `0`,
        priceCurrency: `USD`,
      },
      aggregateRating: {
        '@type': `AggregateRating`,
        ratingValue: `4.9`,
        ratingCount: `100`,
      },
    },
    {
      '@type': `SoftwareApplication`,
      name: `Gertrude AM`,
      operatingSystem: `iOS`,
      applicationCategory: `EntertainmentApplication`,
      description: `A safe podcast app for kids with PIN-protected content control.`,
      offers: {
        '@type': `Offer`,
        price: `10.00`,
        priceCurrency: `USD`,
        priceValidUntil: `2026-12-31`,
      },
      aggregateRating: {
        '@type': `AggregateRating`,
        ratingValue: `5`,
        ratingCount: `25`,
      },
    },
  ],
};
