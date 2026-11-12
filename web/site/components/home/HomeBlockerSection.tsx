'use client';

import { motion, useSpring } from 'framer-motion';
import { ChevronRightIcon, CircleHelpIcon, ShieldCheckIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import { homeRubik } from '@/components/home/HomeHero';
import HomeLetterRipple from '@/components/home/HomeLetterRipple';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { useMotionPreferences } from '@/lib/home-motion';
import { useIntersectionVisibility } from '@/lib/hooks';

const HomeBlockerSection: React.FC = () => (
  <section
    aria-labelledby="blocker-heading"
    className="border-t border-stone-200/80 bg-white"
  >
    <HomeSectionRails className="bg-white px-8 pt-20 sm:pt-28 lg:px-10 lg:pt-40">
      <div className="max-w-4xl sm:pl-6 lg:pl-16">
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
          Gertrude <HomeLetterRipple text="Blocker" />
        </h2>
        <p className="mt-4 max-w-2xl text-lg leading-7 text-stone-600 sm:text-xl sm:leading-8">
          <strong className="font-semibold text-stone-950">
            Close the gaps in Screen Time.
          </strong>
          {` `}
          Gertrude Blocker works alongside Apple’s parental controls to block GIF search,
          web image results, explicit album artwork, and other loopholes Apple leaves
          open. It’s free.
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

const BlockerGroupsFeature: React.FC = () => {
  const [blockedGroups, setBlockedGroups] = React.useState(
    blockerGroups.map((group) => group.blocked),
  );
  const { reducedMotion } = useMotionPreferences();
  const count = blockedGroups.filter(Boolean).length;

  return (
    <div className="relative -mx-8 w-[calc(100%+4rem)] bg-white pb-24 max-xl:overflow-x-clip sm:pb-32 lg:-mx-10 lg:w-[calc(100%+5rem)] xl:aspect-video xl:pb-0">
      <img
        src="/home/grainy-gradient.webp"
        srcSet="/home/grainy-gradient-1000.webp 1000w, /home/grainy-gradient-1280.webp 1280w, /home/grainy-gradient-1600.webp 1600w, /home/grainy-gradient.webp 2000w"
        sizes="(min-width: 1280px) 1280px, 100vw"
        alt=""
        width={2000}
        height={2000}
        loading="lazy"
        decoding="async"
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
      <div
        aria-hidden
        className="pointer-events-none absolute bottom-0 left-1/2 z-[2] flex h-full w-screen -translate-x-1/2 items-end justify-center overflow-hidden"
      >
        <div className="relative aspect-[3/2] min-h-full min-w-full shrink-0">
          <img
            src="/home/landscape-bg-no-background.webp"
            srcSet="/home/landscape-bg-no-background-1600.webp 1600w, /home/landscape-bg-no-background-2400.webp 2400w, /home/landscape-bg-no-background-2560.webp 2560w, /home/landscape-bg-no-background.webp 3024w"
            sizes="(min-width: 1280px) 100vw, (min-width: 640px) max(100vw, 1152px), max(100vw, 1248px)"
            alt=""
            width={3024}
            height={457}
            loading="lazy"
            decoding="async"
            className="absolute inset-x-0 bottom-0 w-full"
          />
        </div>
      </div>
      <p className="relative z-10 max-w-2xl px-8 py-8 text-base leading-7 text-stone-600 sm:px-12 sm:py-12 sm:text-lg xl:py-16 xl:pr-16 xl:pl-[6.5rem]">
        <strong className="mb-2 block text-xl font-semibold text-stone-950">
          Block whole categories with one choice.
        </strong>
        Turn on protection for GIFs, Spotlight searches, ads, AI features, music artwork,
        and more. Choose what fits each device, and change it anytime from your Gertrude
        account.
      </p>

      <div
        role="group"
        aria-label="Example Blocked Groups settings"
        className="relative z-10 mx-auto mt-4 w-[calc(100%-4rem)] max-w-xl [transform:rotate(2deg)] xl:absolute xl:right-24 xl:bottom-16 xl:mt-0 xl:w-[52%] xl:max-w-none xl:[transform:perspective(900px)_rotateX(7deg)_rotateY(-8deg)_rotateZ(5deg)]"
        style={{
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
            <span
              role="status"
              aria-live="polite"
              aria-atomic="true"
              className="shrink-0 rounded-md border border-violet-300 bg-violet-50 px-2 py-1 text-xs font-medium text-violet-700"
            >
              <span className="sr-only">
                {count} of {blockerGroups.length} categories blocked
              </span>
              <span aria-hidden className="flex items-center gap-1 tabular-nums">
                <span className="relative inline-block h-[1.1em] w-[1ch] overflow-hidden">
                  <motion.span
                    initial={false}
                    animate={{ y: `${-count * 100}%` }}
                    transition={
                      reducedMotion
                        ? { duration: 0 }
                        : { type: `spring`, stiffness: 300, damping: 25, mass: 0.7 }
                    }
                    className="absolute inset-0"
                  >
                    {Array.from({ length: blockerGroups.length + 1 }, (_, digit) => (
                      <span
                        key={digit}
                        className="absolute inset-x-0 flex h-full items-center justify-center"
                        style={{ top: `${digit * 100}%` }}
                      >
                        {digit}
                      </span>
                    ))}
                  </motion.span>
                </span>
                of {blockerGroups.length}
              </span>
            </span>
          </div>
          <div className="overflow-hidden rounded-xl border border-stone-200 bg-white/90 shadow shadow-stone-300/30">
            {blockerGroups.map((group, index) => (
              <BlockerGroupPreview
                key={group.title}
                {...group}
                blocked={blockedGroups[index] ?? false}
                reducedMotion={reducedMotion}
                onToggle={() =>
                  setBlockedGroups((current) =>
                    current.map((blocked, item) => (item === index ? !blocked : blocked)),
                  )
                }
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

interface BlockerGroupPreviewProps {
  title: string;
  description: string;
  blocked: boolean;
  reducedMotion: boolean;
  onToggle: () => void;
}

const BlockerGroupPreview: React.FC<BlockerGroupPreviewProps> = ({
  title,
  description,
  blocked,
  reducedMotion,
  onToggle,
}) => {
  const descriptionId = React.useId();
  const scale = useSpring(1, { stiffness: 450, damping: 18, mass: 0.6 });
  const transition = { duration: reducedMotion ? 0 : 0.2 };

  React.useEffect(() => {
    if (reducedMotion) scale.jump(1);
  }, [reducedMotion, scale]);

  return (
    <button
      type="button"
      role="switch"
      aria-checked={blocked}
      aria-label={`${title} blocking`}
      aria-describedby={descriptionId}
      onClick={() => {
        if (!reducedMotion) {
          scale.jump(0.8);
          scale.set(1);
        }
        onToggle();
      }}
      className="flex w-full cursor-pointer items-center gap-3 border-t border-stone-200 px-3 py-3 text-left outline-none transition-colors first:border-t-0 hover:bg-violet-50/60 focus-visible:bg-violet-50 focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-violet-500 motion-reduce:transition-none sm:gap-4 sm:px-4"
    >
      <motion.span
        aria-hidden
        style={{ scale }}
        className={`flex size-5 shrink-0 items-center justify-center rounded-full border transition-colors duration-200 motion-reduce:transition-none ${
          blocked ? `border-violet-500 bg-violet-500` : `border-stone-300 bg-white`
        }`}
      >
        <svg
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth={3}
          strokeLinecap="round"
          strokeLinejoin="round"
          className="size-3.5 translate-y-px text-white"
        >
          <motion.path
            d="M 5 12 L 9 16 L 19 6"
            initial={false}
            animate={{ pathLength: blocked ? 1 : 0, opacity: blocked ? 1 : 0 }}
            transition={transition}
          />
        </svg>
      </motion.span>
      <span className="min-w-0 flex-1">
        <span className="flex flex-wrap items-center gap-2">
          <span className="text-sm font-medium text-stone-900 sm:text-base">{title}</span>
          <span aria-hidden className="grid">
            <motion.span
              initial={false}
              animate={{ opacity: blocked ? 1 : 0 }}
              transition={transition}
              className="col-start-1 row-start-1 rounded-md border border-violet-300 bg-violet-50 px-1.5 py-0.5 text-center text-[10px] font-medium text-violet-700 sm:text-xs"
            >
              Blocked
            </motion.span>
            <motion.span
              initial={false}
              animate={{ opacity: blocked ? 0 : 1 }}
              transition={transition}
              className="col-start-1 row-start-1 rounded-md border border-stone-300 bg-stone-50 px-1.5 py-0.5 text-center text-[10px] font-medium text-stone-700 sm:text-xs"
            >
              Not Blocked
            </motion.span>
          </span>
        </span>
        <span
          id={descriptionId}
          className="mt-0.5 block text-xs leading-5 text-stone-500 sm:text-sm"
        >
          {description}
        </span>
      </span>
      <CircleHelpIcon aria-hidden className="size-5 shrink-0 text-stone-400" />
    </button>
  );
};

const BlockerCoverageGraph: React.FC = () => {
  const graphRef = React.useRef<HTMLElement>(null);
  const [phase, setPhase] = React.useState(0);
  const inView = useIntersectionVisibility(graphRef, 0.45);
  const { reducedMotion: reduceMotion } = useMotionPreferences();

  React.useEffect(() => {
    if (!inView) return;
    if (reduceMotion) {
      setPhase(3);
      return;
    }
    const timers = [
      setTimeout(() => setPhase((current) => Math.max(current, 1)), 200),
      setTimeout(() => setPhase((current) => Math.max(current, 2)), 1900),
      setTimeout(() => setPhase(3), 2200),
    ];
    return () => timers.forEach(clearTimeout);
  }, [inView, reduceMotion]);

  return (
    <figure
      ref={graphRef}
      className="relative -mx-8 mt-12 flex w-[calc(100%+4rem)] flex-col items-center bg-white px-6 py-16 sm:mt-16 sm:px-12 sm:py-20 lg:-mx-10 lg:mt-24 lg:w-[calc(100%+5rem)] lg:px-20 lg:py-24"
    >
      <img
        src="/home/grainy-gradient.webp"
        srcSet="/home/grainy-gradient-1000.webp 1000w, /home/grainy-gradient-1280.webp 1280w, /home/grainy-gradient-1600.webp 1600w, /home/grainy-gradient.webp 2000w"
        sizes="(min-width: 1280px) 1280px, 100vw"
        alt=""
        width={2000}
        height={2000}
        loading="lazy"
        decoding="async"
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
      <div className="relative z-10 aspect-square w-full max-w-72 sm:size-96 sm:max-w-none lg:size-[28rem]">
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
            className="home-js-reveal home-blocker-arc"
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
            className="home-js-reveal home-blocker-arc"
            opacity={phase >= 2 ? 1 : 0}
            style={{
              strokeDashoffset: phase >= 2 ? 0 : 100,
              transition: reduceMotion
                ? `none`
                : `stroke-dashoffset 750ms cubic-bezier(0.22, 1, 0.36, 1)`,
            }}
          />
          <text
            className="home-js-reveal"
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
            className="home-js-reveal"
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
            className={`home-js-reveal absolute text-lg transition-[filter,opacity,transform] duration-700 ease-out motion-reduce:transition-none sm:text-[1.375rem] lg:text-[1.625rem] ${
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
          className={`home-js-reveal origin-center text-pretty bg-gradient-to-r from-violet-950/85 to-fuchsia-950/85 bg-clip-text text-xl leading-8 text-transparent transition-[opacity,transform] duration-500 motion-reduce:transition-none sm:text-2xl sm:leading-9 ${
            phase >= 2
              ? `scale-[0.8] opacity-50`
              : phase >= 1
                ? `scale-100 opacity-100`
                : `scale-100 opacity-0`
          }`}
        >
          Screen Time is a strong foundation, but it leaves some glaring holes.
        </p>
        <p
          className={`home-js-reveal mt-4 text-pretty bg-gradient-to-r from-violet-950/85 to-fuchsia-950/85 bg-clip-text text-xl leading-8 text-transparent transition-[opacity,transform] duration-500 motion-reduce:transition-none sm:text-2xl sm:leading-9 ${
            phase >= 2 ? `translate-y-0 opacity-100` : `translate-y-2 opacity-0`
          }`}
        >
          Gertrude Blocker fills them in.
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
          loading="lazy"
          decoding="async"
          className="h-12 w-auto sm:h-14"
        />
      </a>
      <figcaption className="sr-only">
        Screen Time is a strong foundation, but it leaves some glaring holes. Gertrude
        Blocker fills them in.
      </figcaption>
    </figure>
  );
};

const screenTimeArc = `M 50 8 A 42 42 0 1 1 16.021286 25.313019`;
const blockerArc = `M 16.021286 25.313019 A 42 42 0 0 1 50 8`;
const screenTimeLabelArc = `M 54.183476 97.817346 A 48 48 0 0 0 97.817346 54.183476`;
const blockerLabelArc = `M 11.167184 21.786308 A 48 48 0 0 1 50 2`;
