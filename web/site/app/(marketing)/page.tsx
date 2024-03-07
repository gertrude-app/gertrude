import React from 'react';
import type { NextPage } from 'next';
import HeroBlock from '../../components/HeroBlock';
import PeaceOfMindForParentsBlock from '../../components/PeaceOfMindForParentsBlock';
import DepressingStatisticsBlock from '../../components/DepressingStatisticsBlock';
import SuperScrollerBlock from '../../components/SuperScrollerBlock';
import FeaturesBlock from '../../components/FeaturesBlock';
import DefenseInDepthBlock from '../../components/DefenseInDepthBlock';
import TestimonialsBlock from '../../components/TestimonialsBlock';
import CTABlock from '../../components/CTABlock';

export const metadata = {
  title: `Gertrude | Mac Internet Filter, Parental Controls and Activity Monitoring`,
  description: `Protect your kids online with easy-to-use Mac internet filtering, internet blocking, and mac keylogging.`,
  openGraph: {
    title: `Gertrude | Mac Internet Filter, Parental Controls and Activity Monitoring`,
    description: `Protect your kids online with easy-to-use Mac internet filtering, internet blocking, and mac keylogging.`,
    images: [
      {
        url: `/og-images/main.jpg`,
        width: 1200,
        height: 630,
        alt: `Gertrude | Mac Internet Filter, Parental Controls and Activity Monitoring`,
      },
    ],
  },
};

const HomePage: NextPage = () => (
  <main>
    <HeroBlock />
    <PeaceOfMindForParentsBlock />
    <DepressingStatisticsBlock />
    <SuperScrollerBlock />
    <FeaturesBlock />
    <DefenseInDepthBlock />
    <TestimonialsBlock />
    <CTABlock />
  </main>
);

export default HomePage;
