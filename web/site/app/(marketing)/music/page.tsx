import type { NextPage } from 'next';
import FaqBlock from './FaqBlock';
import HeroBlock from './HeroBlock';
import PlayerBlock from './PlayerBlock';
import PricingBlock from './PricingBlock';
import ProblemBlock from './ProblemBlock';
import { createMetadata } from '@/lib/seo';

export const metadata = createMetadata(
  `Gertrude Music | Parent-Approved Apple Music App for Kids`,
  `Gertrude Music is a parent-managed music app without open-ended browsing. Approve Apple Music artists and albums; kids listen only to the library you choose.`,
);

const MusicPage: NextPage = () => (
  <main className="overflow-hidden bg-white font-lexend">
    <HeroBlock />
    <ProblemBlock />
    <PlayerBlock />
    <PricingBlock />
    <FaqBlock />
  </main>
);

export default MusicPage;
