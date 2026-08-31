import type { NextPage } from 'next';
import HomeBlockerSection from '@/components/home/HomeBlockerSection';
import HomeHero from '@/components/home/HomeHero';
import HomeMacAppSection from '@/components/home/HomeMacAppSection';
import HomeProblemSection from '@/components/home/HomeProblemSection';
import HomeTrustStrip from '@/components/home/HomeTrustStrip';

const HomePage: NextPage = () => (
  <main>
    <HomeHero />
    <HomeTrustStrip />
    <HomeProblemSection />
    <HomeMacAppSection />
    <HomeBlockerSection />
  </main>
);

export default HomePage;
