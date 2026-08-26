import {
  ArrowDownIcon,
  ArrowRightIcon,
  AudioLinesIcon,
  ScanEyeIcon,
  ShieldCheckIcon,
} from 'lucide-react';
import { Rubik } from 'next/font/google';
import React from 'react';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import { PARENTS_APP_URL } from '@/lib/urls';

// eslint-disable-next-line @stylistic/quotes
const rubik = Rubik({ subsets: ['latin'], display: 'swap' });

interface HeroWordProps {
  children: React.ReactNode;
  delay: number;
}

const HeroWord: React.FC<HeroWordProps> = ({ children, delay }) => (
  <span className="hero-word" style={{ animationDelay: `${delay}ms` }}>
    {children}
  </span>
);

const HomeHero: React.FC = () => (
  <section
    className="-mt-[4.5rem] flex min-h-screen w-full flex-col items-center justify-center bg-cover bg-bottom"
    style={{
      backgroundImage: `linear-gradient(to bottom, rgb(255 255 255) 0%, rgb(255 255 255) 8%, rgb(255 255 255 / 0) 28%), url('/home/hero-background.png')`,
    }}
  >
    <div aria-hidden className="mb-12 flex items-center">
      <img
        src="/app-icons/music.webp"
        alt=""
        className="-rotate-12 size-14 rounded-[14px] shadow-lg shadow-stone-900/10 ring-1 ring-black/5 z-0 -mr-1"
      />
      <img
        src="/app-icons/gertrude.webp"
        alt=""
        className="size-14 rounded-[14px] shadow-lg shadow-stone-900/10 ring-1 ring-black/5 z-10 -mt-4"
      />
      <img
        src="/app-icons/podcasts.webp"
        alt=""
        className="rotate-12 size-14 rounded-[14px] shadow-lg shadow-stone-900/10 ring-1 ring-black/5 z-20 -ml-1"
      />
    </div>
    <h1
      className={`${rubik.className} max-w-6xl font-semibold tracking-[-0.035em] leading-[1.45em] text-stone-950 text-5xl text-center`}
    >
      <HeroWord delay={100}>Real</HeroWord>
      {` `}
      <span className="hero-phrase hero-phrase-safety rounded-3xl inline-flex items-center">
        <span className="hero-phrase-icon">
          <span className="hero-phrase-icon-graphic">
            <ShieldCheckIcon className="size-10" />
          </span>
        </span>
        <span>
          <HeroWord delay={190}>internet</HeroWord>
          {` `}
          <HeroWord delay={280}>safety,</HeroWord>
        </span>
      </span>
      <br />
      <span className="hero-phrase hero-phrase-accountability rounded-3xl inline-flex items-center">
        <span className="hero-phrase-icon">
          <span className="hero-phrase-icon-graphic">
            <ScanEyeIcon className="size-10" />
          </span>
        </span>
        <span>
          <HeroWord delay={1110}>accountability,</HeroWord>
        </span>
      </span>
      {` `}
      <HeroWord delay={1940}>and</HeroWord>
      {` `}
      <span className="hero-phrase hero-phrase-media rounded-3xl inline-flex items-center">
        <span className="hero-phrase-icon">
          <span className="hero-phrase-icon-graphic">
            <AudioLinesIcon className="size-10" />
          </span>
        </span>
        <span>
          <HeroWord delay={2030}>curated</HeroWord>
          {` `}
          <HeroWord delay={2120}>media</HeroWord>
        </span>
      </span>
      <br />
      <HeroWord delay={2950}>for</HeroWord>
      {` `}
      <span className="hero-phrase hero-phrase-apple rounded-3xl inline-flex items-center">
        <span className="hero-phrase-icon">
          <span className="hero-phrase-icon-graphic">
            <img src="/apple-logo.svg" alt="" className="size-10 translate-y-[-3px]" />
          </span>
        </span>
        <span>
          <HeroWord delay={3040}>Apple</HeroWord>
          {` `}
          <HeroWord delay={3130}>families.</HeroWord>
        </span>
      </span>
    </h1>
    <p className="mt-10 max-w-3xl text-center text-xl leading-8 text-stone-600">
      Strict filtering and optional activity monitoring on Mac, focused safeguards for
      iPhone and iPad, and parent-approved music and podcasts—all connected to one family
      account.
    </p>
    <div className="mt-8 flex flex-wrap justify-center gap-3">
      <HomeButtonLink
        href={`${PARENTS_APP_URL}/signup?v=new_site`}
        size="hero"
        variant="primary"
      >
        Get started free
        <ArrowRightIcon className="size-4" />
      </HomeButtonLink>
      <HomeButtonLink href="#internet-safety" size="hero" variant="secondary">
        See how it works
        <ArrowDownIcon className="size-4" />
      </HomeButtonLink>
    </div>
  </section>
);

export default HomeHero;
