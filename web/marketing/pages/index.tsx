import CTABlock from 'components/CTABlock';
import DefenseInDepthBlock from 'components/DefenseInDepthBlock';
import DreamToRealityBlock from 'components/DreamToRealityBlock';
import HeroBlock from 'components/HeroBlock';
import LosingBattleBlock from 'components/LosingBattleBlock';
import MainHeader from 'components/MainHeader';
import SafeIsNowPossibleBlock from 'components/SafeIsNowPossibleBlock';
import type { NextPage } from 'next';

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
    </main>
  );
};

export default Home;
