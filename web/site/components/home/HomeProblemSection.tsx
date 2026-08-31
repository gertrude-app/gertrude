'use client';

import { ShieldCheckIcon } from 'lucide-react';
import { Rubik } from 'next/font/google';
import React from 'react';
import HomeSectionRails from '@/components/home/HomeSectionRails';

// eslint-disable-next-line @stylistic/quotes
const rubik = Rubik({ subsets: ['latin'], display: 'swap' });

const entryPoints = [
  `A browser.`,
  `An app.`,
  `A search.`,
  `A message.`,
  `An image picker.`,
  `A private window.`,
  `A media catalog.`,
  `A new website.`,
  `A social feed.`,
  `A shared link.`,
  `A video.`,
  `A group chat.`,
  `An AI chatbot.`,
  `A game.`,
  `A recommendation.`,
  `A file download.`,
];

const HomeProblemSection: React.FC = () => (
  <section
    id="internet-safety"
    className="scroll-mt-24 border-t border-stone-200/80 bg-white"
  >
    <HomeSectionRails className="bg-stone-50 px-8 py-28 lg:px-10 lg:py-40">
      <div className="pl-4 sm:pl-6">
        <h2 className="max-w-6xl text-pretty text-3xl font-semibold leading-[1.05] tracking-[-0.04em] text-stone-950 sm:text-4xl lg:text-5xl">
          The worst of the internet has never been easier to reach.
        </h2>

        <EntryPointList />
      </div>
    </HomeSectionRails>

    <div className="border-y border-stone-200/80">
      <HomeSectionRails className="bg-white">
        <SolutionCard />
      </HomeSectionRails>
    </div>
  </section>
);

export default HomeProblemSection;

const SolutionCard: React.FC = () => (
  <div className="relative w-full overflow-hidden px-6 py-20 text-center sm:px-12 lg:px-20 lg:py-28">
    <img
      src="/home/grainy-gradient.png"
      alt=""
      className="pointer-events-none absolute inset-0 z-0 size-full object-fill opacity-20"
    />
    <div
      aria-hidden
      className="pointer-events-none absolute inset-0 z-0 bg-[url('/home/dot-noise-pattern.svg')] bg-[length:1440px_1440px] bg-repeat"
      style={{
        WebkitMaskImage: `linear-gradient(to bottom, transparent, black)`,
        maskImage: `linear-gradient(to bottom, transparent, black)`,
      }}
    />
    <div
      aria-hidden
      className="pointer-events-none absolute inset-0 z-0 bg-[radial-gradient(circle_at_center,white_0%,rgba(255,255,255,0.85)_30%,rgba(255,255,255,0)_70%)]"
    />
    <div
      aria-hidden
      className="relative z-10 mx-auto flex items-center justify-center gap-5"
    >
      <img src="/home/safety-padlock.svg" alt="" className="h-11 w-auto sm:h-[3.75rem]" />
      <img
        src="/home/safety-logo-stone.svg"
        alt=""
        className="size-12 shrink-0 sm:size-16"
      />
      <img src="/home/safety-shield.svg" alt="" className="h-11 w-auto sm:h-[3.75rem]" />
    </div>
    <h3
      className={`${rubik.className} relative z-10 mx-auto mt-10 max-w-4xl text-4xl font-semibold leading-[1.12] tracking-[-0.04em] text-stone-950 sm:text-5xl`}
    >
      Gertrude makes devices
      <span className="mt-3 block">
        <SolutionSafetyPhrase />
      </span>
    </h3>
    <p className="relative z-10 mx-auto mt-8 max-w-3xl text-xl leading-8 text-transparent bg-gradient-to-r from-violet-950/70 to-fuchsia-950/70 bg-clip-text">
      You shouldn’t have to chase every new path to harmful content. Gertrude brings
      strong protection, honest accountability, and thoughtfully curated media directly to
      Macs, iPhones, and iPads.
    </p>
  </div>
);

const SolutionSafetyPhrase: React.FC = () => {
  const phraseRef = React.useRef<HTMLSpanElement>(null);
  const [hasEntered, setHasEntered] = React.useState(false);

  React.useEffect(() => {
    const phrase = phraseRef.current;
    if (!phrase) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting) return;
        setHasEntered(true);
        observer.disconnect();
      },
      { threshold: 0.6 },
    );

    observer.observe(phrase);
    return () => observer.disconnect();
  }, []);

  return (
    <span
      ref={phraseRef}
      className={`${
        rubik.className
      } home-solution-phrase rounded-3xl inline-flex items-center font-semibold leading-[1.45em] tracking-[-0.035em] ${
        hasEntered ? `home-solution-phrase-visible` : ``
      }`}
    >
      <span aria-hidden className="home-solution-phrase-icon">
        <span className="home-solution-phrase-icon-graphic">
          <ShieldCheckIcon className="size-10" />
        </span>
      </span>
      <span>truly safe.</span>
    </span>
  );
};

const EntryPointList: React.FC = () => {
  const listRef = React.useRef<HTMLUListElement>(null);
  const [hasEntered, setHasEntered] = React.useState(false);

  React.useEffect(() => {
    const list = listRef.current;
    if (!list) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting) return;
        setHasEntered(true);
        observer.disconnect();
      },
      { threshold: 0.2 },
    );

    observer.observe(list);
    return () => observer.disconnect();
  }, []);

  return (
    <ul
      ref={listRef}
      className="mt-16 flex max-w-6xl flex-wrap gap-x-[0.3em] gap-y-[0.12em] text-3xl font-medium leading-[1.12] tracking-[-0.035em] text-stone-400 sm:text-4xl lg:text-5xl"
    >
      {entryPoints.map((entryPoint, index) => (
        <li
          key={entryPoint}
          className={
            hasEntered
              ? `home-problem-entry-point`
              : `opacity-0 motion-reduce:opacity-100`
          }
          style={{ animationDelay: hasEntered ? `${index * 100}ms` : `0ms` }}
        >
          {entryPoint}
        </li>
      ))}
    </ul>
  );
};
