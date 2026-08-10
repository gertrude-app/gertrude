import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import Button from './Button';
import Logo from './Logo';
import MusicHeroPhones from './MusicHeroPhones';

const MusicBlock: React.FC = () => (
  <section
    id="music"
    className="relative isolate min-h-screen overflow-hidden bg-slate-950 text-white"
  >
    <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_74%_42%,rgba(124,58,237,0.25),transparent_34%),radial-gradient(circle_at_12%_80%,rgba(217,70,239,0.14),transparent_30%)]" />
    <div className="relative mx-auto grid min-h-screen max-w-[1440px] items-center gap-12 px-6 py-20 xs:px-8 xs:py-24 sm:px-12 lg:grid-cols-[0.82fr_1.18fr] lg:gap-10 lg:px-20 xl:gap-20">
      <div className="relative z-10 max-w-xl">
        <Logo product="music" size={28} />
        <h2 className="mt-7 text-4xl font-semibold leading-[1.02] tracking-[-0.045em] xs:text-5xl sm:text-6xl lg:text-5xl xl:text-6xl">
          <span className="block">The music you choose.</span>
          <span className="mt-2 block bg-gradient-to-r from-violet-300 to-fuchsia-300 bg-clip-text pb-2 text-transparent">
            Nothing else.
          </span>
        </h2>
        <p className="mt-6 max-w-lg text-base leading-relaxed text-violet-100/70 xs:text-lg sm:text-xl">
          Approve artists and albums from your Gertrude account. Your child listens from
          that library without browsing the rest of Apple Music.
        </p>
        <div className="mt-8 flex flex-col items-start gap-4 xs:flex-row xs:items-center">
          <Button
            type="link"
            href="/music"
            color="primary"
            size="lg"
            Icon={ArrowRightIcon}
            iconPosition="right"
            className="w-full xs:w-auto max-sm:gap-2 max-sm:rounded-xl max-sm:px-5 max-sm:py-3 max-sm:text-base max-sm:leading-6"
          >
            Explore Gertrude Music
          </Button>
        </div>
        <p className="mt-5 text-sm leading-relaxed text-white/45">
          Gertrude Medium · $5/month for your whole family
          <br />
          Active Apple Music subscription required
        </p>
      </div>

      <MusicHeroPhones className="w-[108%] max-w-[34rem] xs:w-full xl:max-w-[38rem]" />
    </div>
  </section>
);

export default MusicBlock;
