import type { AppStoreRating } from '@/lib/app-store-ratings';
import type { NextPage } from 'next';
import HomeBlockerSection from '@/components/home/HomeBlockerSection';
import HomeClosingCTA from '@/components/home/HomeClosingCTA';
import HomeCuratedMediaSection from '@/components/home/HomeCuratedMediaSection';
import HomeHero from '@/components/home/HomeHero';
import HomeHowItWorksSection from '@/components/home/HomeHowItWorksSection';
import HomeMacAppSection from '@/components/home/HomeMacAppSection';
import HomePricingSection from '@/components/home/HomePricingSection';
import HomeProblemSection from '@/components/home/HomeProblemSection';
import HomeTestimonialsSection from '@/components/home/HomeTestimonialsSection';
import HomeTrustStrip from '@/components/home/HomeTrustStrip';
import { appStoreRatings } from '@/lib/app-store-ratings';
import { pricingPlans } from '@/lib/pricing';
import { createMetadata } from '@/lib/seo';

export const metadata = createMetadata(
  `Gertrude | Internet Safety, Accountability, & Curated Media for Apple Devices`,
  `Strict internet filtering, accountability, and parent-approved music and podcasts for Mac, iPhone, and iPad. Protect your kids, stay accountable, or help someone you care about do the same.`,
);

const HomePage: NextPage = () => (
  <main>
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(JSON_LD) }}
    />
    <HomeHero />
    <HomeTrustStrip />
    <HomeProblemSection />
    <HomeMacAppSection />
    <HomeBlockerSection />
    <HomeCuratedMediaSection />
    <HomeHowItWorksSection />
    <HomeTestimonialsSection />
    <HomePricingSection />
    <HomeClosingCTA />
  </main>
);

export default HomePage;

const offer = (dollars: number): Record<string, string> => ({
  '@type': `Offer`,
  price: dollars.toFixed(2),
  priceCurrency: `USD`,
});

const aggregateRating = ({ rating, count }: AppStoreRating): Record<string, string> => ({
  '@type': `AggregateRating`,
  ratingValue: rating,
  ratingCount: String(count),
});

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
      description: `Blocks everything except the websites and apps you approve, with screenshot and keystroke monitoring for accountability.`,
      offers: offer(pricingPlans.full.priceDollars),
    },
    {
      '@type': `SoftwareApplication`,
      name: `Gertrude Blocker`,
      operatingSystem: `iOS`,
      applicationCategory: `UtilitiesApplication`,
      description: `Closes the gaps in Screen Time on iPhone and iPad, blocking GIF search, web image results, explicit album artwork, and more.`,
      offers: offer(pricingPlans.free.priceDollars),
      aggregateRating: aggregateRating(appStoreRatings.blocker),
    },
    {
      '@type': `SoftwareApplication`,
      name: `Gertrude Music`,
      operatingSystem: `iOS`,
      applicationCategory: `MusicApplication`,
      description: `A full-featured music app that plays only the artists and albums you approve.`,
      offers: offer(pricingPlans.medium.priceDollars),
    },
    {
      '@type': `SoftwareApplication`,
      name: `Gertrude Podcasts`,
      alternateName: `Gertrude AM`,
      operatingSystem: `iOS`,
      applicationCategory: `EntertainmentApplication`,
      description: `A podcast app for approved shows, where finding or adding a new show takes your PIN.`,
      offers: offer(pricingPlans.light.priceDollars),
      aggregateRating: aggregateRating(appStoreRatings.podcasts),
    },
  ],
};
