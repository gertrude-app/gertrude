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
