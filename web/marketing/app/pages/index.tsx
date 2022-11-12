import {
  CTABlock,
  DefenseInDepthBlock,
  HeroBlock,
  LosingBattleBlock,
  MainFooter,
  MainHeader,
  PeaceOfMindBlock,
  SafeIsNowPossibleBlock,
} from '@marketing/components';
import type { NextPage } from 'next';

const Home: NextPage = () => (
  <main className="overflow-hidden">
    <MainHeader />
    <HeroBlock />
    <PeaceOfMindBlock />
    <LosingBattleBlock />
    <SafeIsNowPossibleBlock />
    <DefenseInDepthBlock />
    <CTABlock />
    <MainFooter />
  </main>
);

export default Home;
