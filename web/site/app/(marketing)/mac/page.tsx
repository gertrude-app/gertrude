import React from 'react';
import type { NextPage } from 'next';
import CTABlock from '@/components/CTABlock';
import DefenseInDepthBlock from '@/components/DefenseInDepthBlock';
import DepressingStatisticsBlock from '@/components/DepressingStatisticsBlock';
import HeroBlock from '@/components/HeroBlock';
import PeaceOfMindForParentsBlock from '@/components/PeaceOfMindForParentsBlock';
import SuperScrollerBlock from '@/components/SuperScrollerBlock';
import TestimonialsBlock from '@/components/TestimonialsBlock';
import { createMetadata } from '@/lib/seo';

export const metadata = createMetadata(
  `Gertrude | Mac Internet Filter, Parental Controls and Activity Monitoring`,
  `Protect your kids online with easy-to-use Mac internet filtering, internet blocking, and mac keylogging`,
);

const HomePage: NextPage = () => (
  <main>
    <HeroBlock />
    <PeaceOfMindForParentsBlock />
    <DepressingStatisticsBlock />
    <SuperScrollerBlock />
    <DefenseInDepthBlock />
    <TestimonialsBlock />
    <CTABlock />
  </main>
);

export default HomePage;
