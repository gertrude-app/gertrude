'use client';

import {
  CheckIcon,
  ChevronRightIcon,
  CircleHelpIcon,
  ShieldCheckIcon,
} from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import { homeRubik } from '@/components/home/HomeHero';
import HomeSectionRails from '@/components/home/HomeSectionRails';

const HomeBlockerSection: React.FC = () => (
  <section
    aria-labelledby="blocker-heading"
    className="border-t border-stone-200/80 bg-white"
  >
    <HomeSectionRails className="bg-white px-8 py-28 lg:px-10 lg:py-40">
      <div className="max-w-4xl pl-12 sm:pl-16">
        <Link
          href="/iphone-and-ipad"
          className="group mb-8 flex items-center gap-0.5 text-violet-500"
        >
          <span className="font-medium">iPhone &amp; iPad App</span>
          <ChevronRightIcon className="size-5 transition-transform duration-150 group-hover:translate-x-1" />
        </Link>
        <h2
          id="blocker-heading"
          className="max-w-6xl text-pretty text-3xl font-semibold leading-[1.05] tracking-[-0.04em] text-stone-950 sm:text-4xl lg:text-5xl"
        >
          Gertrude <AnimatedBlocker />
        </h2>
        <p className="mt-4 max-w-2xl text-xl leading-8 text-stone-600">
          <strong className="font-semibold text-stone-950">
            Close every Screen Time loophole.
          </strong>
          {` `}
          Gertrude Blocker works alongside Apple’s parental controls to block GIF search,
          web images, explicit artwork, and every other path Screen Time leaves open.
        </p>
      </div>
      <BlockerCoverageGraph />
      <BlockerGroupsFeature />
    </HomeSectionRails>
  </section>
);

export default HomeBlockerSection;

const blockerGroups = [
  {
    title: `Ads`,
    description: `Block the most common ad providers across all apps.`,
    blocked: true,
  },
  {
    title: `AI features`,
    description: `Block certain cloud-based AI features like image recognition.`,
    blocked: true,
  },
  {
    title: `Apple Music`,
    description: `Block artwork and video content in the Apple Music app.`,
    blocked: false,
  },
  {
    title: `GIFs`,
    description: `Block GIFs in Messages #images, WhatsApp, Signal, and more.`,
    blocked: true,
  },
  {
    title: `Spotlight`,
    description: `Block internet searches through Spotlight.`,
    blocked: true,
  },
];

const BlockerGroupsFeature: React.FC = () => (
  <div className="relative -mx-8 aspect-video min-h-[52rem] w-[calc(100%+4rem)] bg-white sm:min-h-[48rem] lg:-mx-10 lg:w-[calc(100%+5rem)] xl:min-h-0">
    <img
      src="/home/grainy-gradient.png"
      alt=""
      className="pointer-events-none absolute inset-0 size-full object-fill opacity-20"
      style={{ transform: `scaleY(-1)` }}
    />
    <div
      aria-hidden
      className="pointer-events-none absolute inset-0 z-0"
      style={{
        WebkitMaskImage: `linear-gradient(to bottom, black, transparent)`,
        maskImage: `linear-gradient(to bottom, black, transparent)`,
      }}
    >
      <div
        className="absolute inset-0 bg-[url('/home/dot-noise-pattern.svg')] bg-[length:1440px_1440px] bg-repeat"
        style={{ backgroundPositionY: `bottom`, transform: `scaleY(-1)` }}
      />
    </div>
    <div
      aria-hidden
      className="pointer-events-none absolute left-[8%] top-[22%] z-[1] h-[78%] w-[110%] -translate-x-1/2 -translate-y-1/2 rounded-[50%] bg-white/85 blur-[80px] sm:blur-[110px]"
    />
    <img
      src="/home/landscape-bg-no-background.png"
      alt=""
      className="pointer-events-none absolute inset-0 z-[2] size-full object-cover object-bottom"
    />
    <p className="relative z-10 max-w-2xl py-8 pr-8 pl-20 text-lg leading-7 text-stone-600 sm:py-12 sm:pr-12 sm:pl-24 lg:py-16 lg:pr-16 lg:pl-[6.5rem]">
      <strong className="mb-2 block text-xl font-semibold text-stone-950">
        Block whole categories with one choice.
      </strong>
      Block groups bundle related loopholes—GIFs, Spotlight, ads, AI features, music
      artwork, and more—so protection is easy to understand and tailor to each device.
    </p>

    <div
      aria-hidden
      className="absolute right-4 bottom-10 z-10 w-[90%] sm:right-10 sm:bottom-16 sm:w-[78%] md:right-12 md:w-[68%] lg:right-20 lg:w-[56%] xl:right-24 xl:w-[52%]"
      style={{
        transform: `perspective(900px) rotateX(7deg) rotateY(-8deg) rotateZ(5deg)`,
        transformOrigin: `center bottom`,
      }}
    >
      <div className="rounded-2xl border border-white/80 bg-white/75 p-3 shadow-[0_30px_70px_-28px_rgba(76,29,149,0.45)] backdrop-blur-md sm:p-4">
        <div className="flex items-start justify-between gap-4 px-1 pb-3">
          <div>
            <p className="text-sm font-semibold text-stone-900 sm:text-base">
              Blocked Groups
            </p>
            <p className="mt-0.5 text-xs text-stone-500 sm:text-sm">
              These content categories are blocked on this device.
            </p>
          </div>
          <span className="shrink-0 rounded-md border border-violet-300 bg-violet-50 px-2 py-1 text-xs font-medium text-violet-700">
            4 of 7
          </span>
        </div>
        <div className="overflow-hidden rounded-xl border border-stone-200 bg-white/90 shadow shadow-stone-300/30">
          {blockerGroups.map((group) => (
            <BlockerGroupPreview key={group.title} {...group} />
          ))}
        </div>
      </div>
    </div>
  </div>
);

interface BlockerGroupPreviewProps {
  title: string;
  description: string;
  blocked: boolean;
}

const BlockerGroupPreview: React.FC<BlockerGroupPreviewProps> = ({
  title,
  description,
  blocked,
}) => (
  <div className="flex items-center gap-3 border-t border-stone-200 px-3 py-3 first:border-t-0 sm:gap-4 sm:px-4">
    <span
      className={`flex size-5 shrink-0 items-center justify-center rounded-full border ${
        blocked ? `border-violet-500 bg-violet-500` : `border-stone-200 bg-white`
      }`}
    >
      {blocked && (
        <CheckIcon className="size-3.5 translate-y-px text-white" strokeWidth={3} />
      )}
    </span>
    <div className="min-w-0 flex-1">
      <div className="flex flex-wrap items-center gap-2">
        <p className="text-sm font-medium text-stone-900 sm:text-base">{title}</p>
        <span
          className={`rounded-md border px-1.5 py-0.5 text-[10px] font-medium sm:text-xs ${
            blocked
              ? `border-violet-300 bg-violet-50 text-violet-700`
              : `border-stone-300 bg-stone-50 text-stone-700`
          }`}
        >
          {blocked ? `Blocked` : `Not Blocked`}
        </span>
      </div>
      <p className="mt-0.5 text-xs leading-5 text-stone-500 sm:text-sm">{description}</p>
    </div>
    <CircleHelpIcon className="size-5 shrink-0 text-stone-400" />
  </div>
);

const BlockerCoverageGraph: React.FC = () => {
  const graphRef = React.useRef<HTMLElement>(null);
  const [phase, setPhase] = React.useState(0);
  const [reduceMotion, setReduceMotion] = React.useState(false);

  React.useEffect(() => {
    const graph = graphRef.current;
    if (!graph) return;

    const timers: Array<ReturnType<typeof setTimeout>> = [];
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting) return;

        if (window.matchMedia(`(prefers-reduced-motion: reduce)`).matches) {
          setReduceMotion(true);
          setPhase(3);
        } else {
          timers.push(setTimeout(() => setPhase(1), 200));
          timers.push(setTimeout(() => setPhase(2), 1900));
          timers.push(setTimeout(() => setPhase(3), 2200));
        }
        observer.disconnect();
      },
      { threshold: 0.45 },
    );

    observer.observe(graph);
    return () => {
      observer.disconnect();
      timers.forEach(clearTimeout);
    };
  }, []);

  return (
    <figure
      ref={graphRef}
      className="relative -mx-8 mt-24 flex w-[calc(100%+4rem)] flex-col items-center bg-white px-6 py-20 sm:px-12 lg:-mx-10 lg:w-[calc(100%+5rem)] lg:px-20 lg:py-24"
    >
      <img
        src="/home/grainy-gradient.png"
        alt=""
        className="pointer-events-none absolute inset-0 z-0 size-full object-fill opacity-20"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 z-0 bg-[url('/home/dot-noise-pattern.svg')] bg-[length:1440px_1440px] bg-repeat"
        style={{
          backgroundPositionY: `bottom`,
          WebkitMaskImage: `linear-gradient(to bottom, transparent, black)`,
          maskImage: `linear-gradient(to bottom, transparent, black)`,
        }}
      />
      <div
        aria-hidden
        className="pointer-events-none absolute left-1/2 top-[42%] z-[1] h-[72%] w-[76%] -translate-x-1/2 -translate-y-1/2 rounded-[50%] bg-white/85 blur-[80px] sm:blur-[110px]"
      />
      <div className="relative z-10 size-72 sm:size-96 lg:size-[28rem]">
        <svg
          aria-hidden
          viewBox="0 0 100 100"
          className="size-full overflow-visible drop-shadow-sm"
        >
          <defs>
            <linearGradient id="blocker-coverage-gradient" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#8b5cf6" />
              <stop offset="100%" stopColor="#d946ef" />
            </linearGradient>
            <path id="screen-time-label-arc" d={screenTimeLabelArc} />
            <path id="blocker-label-arc" d={blockerLabelArc} />
          </defs>
          <circle cx="50" cy="50" r="42" fill="none" stroke="#f5f5f4" strokeWidth="10" />
          <path
            d={screenTimeArc}
            pathLength="100"
            fill="none"
            stroke="#d6d3d1"
            strokeWidth="10"
            strokeDasharray="100 100"
            opacity={phase >= 1 ? 1 : 0}
            style={{
              strokeDashoffset: phase >= 1 ? 0 : 100,
              transition: reduceMotion
                ? `none`
                : `stroke-dashoffset 1200ms cubic-bezier(0.22, 1, 0.36, 1)`,
            }}
          />
          <path
            d={blockerArc}
            pathLength="100"
            fill="none"
            stroke="url(#blocker-coverage-gradient)"
            strokeWidth="10"
            strokeDasharray="100 100"
            opacity={phase >= 2 ? 1 : 0}
            style={{
              strokeDashoffset: phase >= 2 ? 0 : 100,
              transition: reduceMotion
                ? `none`
                : `stroke-dashoffset 750ms cubic-bezier(0.22, 1, 0.36, 1)`,
            }}
          />
          <text
            fill="#57534e"
            fontSize="4"
            fontWeight="600"
            letterSpacing="0.2"
            textAnchor="middle"
            dy="3"
            style={{
              opacity: phase >= 1 ? 1 : 0,
              transition: reduceMotion ? `none` : `opacity 500ms ease-out`,
            }}
          >
            <textPath href="#screen-time-label-arc" startOffset="50%">
              Apple Screen Time
            </textPath>
          </text>
          <text
            fill="#6d28d9"
            fontSize="3.5"
            fontWeight="600"
            letterSpacing="0.1"
            textAnchor="middle"
            style={{
              opacity: phase >= 2 ? 1 : 0,
              transition: reduceMotion ? `none` : `opacity 500ms ease-out`,
            }}
          >
            <textPath href="#blocker-label-arc" startOffset="50%">
              Gertrude Blocker
            </textPath>
          </text>
        </svg>
        <div aria-hidden className="absolute inset-0 flex items-center justify-center">
          <p
            className={`absolute text-center text-xl font-semibold tracking-[-0.025em] text-stone-800 transition-[filter,opacity,transform] duration-700 ease-out motion-reduce:transition-none sm:text-2xl ${
              phase === 1
                ? `translate-y-0 blur-0 opacity-100`
                : phase >= 2
                  ? `-translate-y-3 blur-sm opacity-0`
                  : `translate-y-3 blur-sm opacity-0`
            }`}
          >
            Screen Time
            <span className="mt-1 block text-base font-normal tracking-normal text-stone-500 sm:text-lg">
              misses some things.
            </span>
          </p>
          <div
            className={`absolute text-lg transition-[filter,opacity,transform] duration-700 ease-out motion-reduce:transition-none sm:text-[1.375rem] lg:text-[1.625rem] ${
              phase >= 2
                ? `translate-y-0 blur-0 opacity-100`
                : `translate-y-3 blur-sm opacity-0`
            }`}
          >
            <span
              className={`${homeRubik.className} home-solution-phrase home-solution-phrase-compact inline-flex items-center rounded-3xl font-semibold leading-[1.45em] tracking-[-0.035em] ${
                phase >= 3 ? `home-solution-phrase-visible` : ``
              }`}
            >
              <span className="home-solution-phrase-icon">
                <span className="home-solution-phrase-icon-graphic">
                  <ShieldCheckIcon className="size-[0.85em]" />
                </span>
              </span>
              <span>The gaps, closed.</span>
            </span>
          </div>
        </div>
      </div>

      <div aria-hidden className="relative z-10 mt-10 w-full max-w-xl text-center">
        <p
          className={`origin-center text-pretty bg-gradient-to-r from-violet-950/85 to-fuchsia-950/85 bg-clip-text text-xl leading-8 text-transparent transition-[opacity,transform] duration-500 motion-reduce:transition-none sm:text-2xl sm:leading-9 ${
            phase >= 2
              ? `scale-[0.8] opacity-50`
              : phase >= 1
                ? `scale-100 opacity-100`
                : `scale-100 opacity-0`
          }`}
        >
          Screen Time provides a strong foundation—but leaves some glaring holes.
        </p>
        <p
          className={`mt-4 text-pretty bg-gradient-to-r from-violet-950/85 to-fuchsia-950/85 bg-clip-text text-xl leading-8 text-transparent transition-[opacity,transform] duration-500 motion-reduce:transition-none sm:text-2xl sm:leading-9 ${
            phase >= 2 ? `translate-y-0 opacity-100` : `translate-y-2 opacity-0`
          }`}
        >
          Gertrude Blocker plugs every loophole Screen Time leaves open.
        </p>
      </div>
      <a
        href="https://apps.apple.com/us/app/gertrude-blocker/id6736368820"
        target="_blank"
        rel="noopener noreferrer"
        className="relative z-10 mt-8"
      >
        <img
          src="/download-on-app-store.svg"
          alt="Download Gertrude Blocker on the App Store"
          width={168}
          height={56}
          className="h-12 w-auto sm:h-14"
        />
      </a>
      <figcaption className="sr-only">
        Screen Time provides a strong foundation, and Gertrude Blocker plugs every
        loophole it leaves open.
      </figcaption>
    </figure>
  );
};

const screenTimeArc = `M 50 8 A 42 42 0 1 1 16.021286 25.313019`;
const blockerArc = `M 16.021286 25.313019 A 42 42 0 0 1 50 8`;
const screenTimeLabelArc = `M 54.183476 97.817346 A 48 48 0 0 0 97.817346 54.183476`;
const blockerLabelArc = `M 11.167184 21.786308 A 48 48 0 0 1 50 2`;

const AnimatedBlocker: React.FC = () => {
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

  const letters = [...`Blocker`];
  const initialDelay = 300;
  const stagger = 80;
  return (
    <span ref={phraseRef}>
      {letters.map((letter, index) => (
        <span
          key={`${letter}-${index}`}
          className={`home-mac-letter-ripple ${
            hasEntered ? `home-mac-letter-ripple-visible` : ``
          }`}
          style={{
            animationDelay: hasEntered ? `${initialDelay + index * stagger}ms` : `0ms`,
          }}
        >
          {letter}
        </span>
      ))}
    </span>
  );
};
