import { ArrowDownIcon } from 'lucide-react';
import React from 'react';
import { AppStoreLink } from './shared';
import Button from '@/components/Button';
import MusicHeroPhones from '@/components/MusicHeroPhones';

const HeroBlock: React.FC = () => (
  <section className="relative isolate overflow-hidden bg-slate-950 text-white">
    <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_75%_28%,rgba(217,70,239,0.2),transparent_32%),radial-gradient(circle_at_55%_72%,rgba(124,58,237,0.18),transparent_34%)]" />
    <div className="relative mx-auto grid max-w-[1440px] items-center gap-6 px-4 pb-10 pt-32 xs:gap-8 xs:px-8 xs:pb-12 sm:px-12 sm:pt-40 lg+:min-h-screen lg+:grid-cols-[0.92fr_1.08fr] lg+:gap-16 lg+:px-20 lg+:pb-16 lg+:pt-32">
      <div className="relative z-10 max-w-2xl">
        <h1 className="font-semibold leading-[0.98] tracking-[-0.05em]">
          <span className="block text-[2.65rem] xs:text-5xl sm:text-6xl lg+:text-[4.5rem]">
            The music you choose.
          </span>
          <span className="mt-3 block bg-gradient-to-r from-violet-300 to-fuchsia-300 bg-clip-text pb-3 text-5xl leading-[1.05] text-transparent xs:text-6xl sm:mt-4 sm:whitespace-nowrap sm:text-7xl lg+:text-[5.25rem]">
            Nothing else.
          </span>
        </h1>
        <p className="mt-7 max-w-xl text-lg leading-relaxed text-violet-100/70 sm:text-xl">
          Approve artists and albums from your Gertrude account. Your child listens from
          that library without browsing the rest of Apple Music.
        </p>
        <div className="mt-9 flex flex-col items-start gap-4 xs:flex-row xs:flex-wrap xs:items-center">
          <AppStoreLink className="h-12 w-full justify-center overflow-hidden rounded-xl bg-white xs:w-auto sm:h-14 sm:rounded-2xl [&_img]:h-full [&_img]:invert" />
          <Button
            type="link"
            href="#how-it-works"
            size="lg"
            color="secondary"
            inverted
            variant="flat"
            Icon={ArrowDownIcon}
            iconPosition="right"
            className="w-full xs:w-auto max-sm:gap-2 max-sm:rounded-xl max-sm:px-6 max-sm:py-3 max-sm:text-base max-sm:leading-6"
          >
            See how it works
          </Button>
        </div>
        <p className="mt-6 text-sm leading-relaxed text-white/45">
          Gertrude Medium · $5/month for your whole family
          <br />
          Active Apple Music subscription required
        </p>
      </div>

      <MusicHeroPhones className="w-[108%] max-w-[36rem] xs:w-full xl:max-w-[42rem]" />
    </div>
  </section>
);

export default HeroBlock;
