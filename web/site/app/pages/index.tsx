import {
  CTABlock,
  DefenseInDepthBlock,
  HeroBlock,
  LosingGameBlock,
  MainFooter,
  MainHeader,
  PeaceOfMindBlock,
  SafeIsNowPossibleBlock,
  TestimonialsBlock,
} from '@site/components';
import type { NextPage } from 'next';

const Home: NextPage = () => (
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

export default Home;
