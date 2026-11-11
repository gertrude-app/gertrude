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
import HomeHeroApps from '@/components/home/HomeHeroApps';
import HomeHeroBackground from '@/components/home/HomeHeroBackground';
import HomeHeroEntrance from '@/components/home/HomeHeroEntrance';
import HomeHeroPhrase from '@/components/home/HomeHeroPhrase';
import HomeHeroRise from '@/components/home/HomeHeroRise';
import { heroSequence } from '@/lib/home-hero-sequence';
import { PARENTS_APP_URL } from '@/lib/urls';

// eslint-disable-next-line @stylistic/quotes
const rubik = Rubik({ subsets: ['latin'], display: 'swap' });

export { rubik as homeRubik };

const subtitle = `Protect your kids, stay accountable, or help someone you care about do the same.`;

interface HeroWordProps {
  children: React.ReactNode;
  delay: number;
}

const HeroWord: React.FC<HeroWordProps> = ({ children, delay }) => (
  <span
    className="hero-word"
    style={{
      animationDelay: `calc(${delay}ms * var(--home-hero-timing-scale, 1))`,
    }}
  >
    {children}
  </span>
);

const HomeHero: React.FC = () => (
  <HomeHeroEntrance className="home-hero relative isolate z-10 -mt-[4.5rem] flex min-h-svh w-full flex-col items-center px-6 sm:px-8 lg:min-h-screen lg:px-0">
    <HomeHeroBackground />
    <div aria-hidden="true" className="min-h-60 flex-1" />
    <HomeHeroApps />
    <h1
      className={`${rubik.className} max-w-6xl text-center text-[clamp(1.5rem,6.7vw,2.5rem)] font-semibold leading-[1.45em] tracking-[-0.035em] text-stone-950 lg:text-5xl lg:leading-[1.45em]`}
    >
      <HeroWord delay={100}>Real</HeroWord>
      {` `}
      <HomeHeroPhrase variant="safety">
        <span className="hero-phrase-icon">
          <span className="hero-phrase-icon-graphic">
            <ShieldCheckIcon className="size-[0.833333em] lg:size-10" />
          </span>
        </span>
        <span>
          <HeroWord delay={190}>internet</HeroWord>
          {` `}
          <HeroWord delay={280}>safety,</HeroWord>
        </span>
      </HomeHeroPhrase>
      <br />
      <HomeHeroPhrase variant="accountability">
        <span className="hero-phrase-icon">
          <span className="hero-phrase-icon-graphic">
            <ScanEyeIcon className="size-[0.833333em] lg:size-10" />
          </span>
        </span>
        <span>
          <HeroWord delay={1110}>accountability,</HeroWord>
        </span>
      </HomeHeroPhrase>
      <br className="lg:hidden" />
      {` `}
      <HeroWord delay={1940}>and</HeroWord>
      {` `}
      <HomeHeroPhrase variant="media">
        <span className="hero-phrase-icon">
          <span className="hero-phrase-icon-graphic">
            <AudioLinesIcon className="size-[0.833333em] lg:size-10" />
          </span>
        </span>
        <span>
          <HeroWord delay={2030}>curated</HeroWord>
          {` `}
          <HeroWord delay={2120}>media</HeroWord>
        </span>
      </HomeHeroPhrase>
      <br />
      <HeroWord delay={2950}>for</HeroWord>
      {` `}
      <HomeHeroPhrase variant="apple">
        <span className="hero-phrase-icon">
          <span className="hero-phrase-icon-graphic">
            <img
              src="/apple-logo.svg"
              alt=""
              width={40}
              height={40}
              decoding="async"
              className="size-[0.833333em] translate-y-[-0.0625em] lg:size-10 lg:translate-y-[-3px]"
            />
          </span>
        </span>
        <span>
          <HeroWord delay={3040}>Apple</HeroWord>
          {` `}
          <HeroWord delay={3130}>devices.</HeroWord>
        </span>
      </HomeHeroPhrase>
    </h1>
    <p className="mt-6 max-w-xl text-center text-lg leading-7 text-stone-800 sm:text-xl sm:leading-8 lg:mt-10 lg:max-w-2xl lg:text-2xl lg:leading-9">
      {subtitle.split(` `).map((word, index) => (
        <React.Fragment key={`${word}-${index}`}>
          {index > 0 && ` `}
          <HomeHeroRise
            blur
            className="inline-block"
            distance={14}
            delay={heroSequence.subtitle + index * heroSequence.subtitleWordStagger}
          >
            {word}
          </HomeHeroRise>
        </React.Fragment>
      ))}
    </p>
    <div className="mt-6 flex w-full max-w-xs flex-col justify-center gap-3 xs:max-w-none xs:flex-row lg:mt-8 lg:w-auto">
      <HomeHeroRise className="flex flex-col" distance={24} delay={heroSequence.actions}>
        <HomeButtonLink
          href={`${PARENTS_APP_URL}/signup?v=new_site`}
          size="hero"
          variant="primary"
        >
          Get started free
          <ArrowRightIcon className="size-4" />
        </HomeButtonLink>
      </HomeHeroRise>
      <HomeHeroRise
        className="flex flex-col"
        distance={24}
        delay={heroSequence.actions + heroSequence.actionStagger}
      >
        <HomeButtonLink href="#internet-safety" size="hero" variant="secondary">
          See how it works
          <ArrowDownIcon className="size-4" />
        </HomeButtonLink>
      </HomeHeroRise>
    </div>
    <div aria-hidden="true" className="min-h-16 flex-1" />
  </HomeHeroEntrance>
);

export default HomeHero;
