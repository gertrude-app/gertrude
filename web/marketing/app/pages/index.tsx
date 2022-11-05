import type { NextPage } from 'next';
import {
  CTABlock,
  DefenseInDepthBlock,
  DreamToRealityBlock,
  HeroBlock,
  LosingBattleBlock,
  MainFooter,
  MainHeader,
  SafeIsNowPossibleBlock,
} from '@marketing/components';

const Home: NextPage = () => {
  return (
    <main className="overflow-hidden">
      <MainHeader />
      <HeroBlock />
      <DreamToRealityBlock />
      <LosingBattleBlock />
      <SafeIsNowPossibleBlock />
      <DefenseInDepthBlock />
      <CTABlock />
      <MainFooter />
    </main>
  );
};

export default Home;
