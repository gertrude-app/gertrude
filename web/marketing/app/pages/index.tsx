import {
  CTABlock,
  DefenseInDepthBlock,
  PeaceOfMindForParentsBlock,
  HeroBlock,
  LosingBattleBlock,
  MainFooter,
  MainHeader,
  SafeIsNowPossibleBlock,
} from '@marketing/components';
import type { NextPage } from 'next';

const Home: NextPage = () => {
  return (
    <main className="overflow-hidden">
      <MainHeader />
      <HeroBlock />
      <PeaceOfMindForParentsBlock />
      <LosingBattleBlock />
      <SafeIsNowPossibleBlock />
      <DefenseInDepthBlock />
      <CTABlock />
      <MainFooter />
    </main>
  );
};

export default Home;
