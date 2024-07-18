import React from 'react';
import type { NextPage } from 'next';
import MainHeader from './home/OldMainHeader';
import HeroBlock from './home/OldHeroBlock';
import PeaceOfMindBlock from './home/OldPeaceOfMindBlock';
import LosingGameBlock from './home/OldLosingGameBlock';
import SafeIsNowPossibleBlock from './home/OldSafeIsNowPossibleBlock';
import DefenseInDepthBlock from './home/OldDefenseInDepthBlock';
import TestimonialsBlock from './home/OldTestimonialsBlock';
import CTABlock from './home/OldCTABlock';
import MainFooter from './home/OldMainFooter';
import { createMetadata } from '@/lib/seo';

export const metadata = createMetadata(
  `Gertrude | Mac Internet Filter, Parental Controls and Activity Monitoring`,
  `Protect your kids online with easy-to-use Mac internet filtering, internet blocking, and mac keylogging`,
);

const HomePage: NextPage = () => (
  <main className="overflow-hidden">
    <MainHeader />
    <HeroBlock />
    <PeaceOfMindBlock />
    <LosingGameBlock />
    <SafeIsNowPossibleBlock />
    <DefenseInDepthBlock />
    <TestimonialsBlock />
    <CTABlock />
    <MainFooter />
  </main>
);

export default HomePage;
