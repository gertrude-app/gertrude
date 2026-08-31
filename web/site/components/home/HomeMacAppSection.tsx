'use client';

import { ChevronRightIcon, FlagIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import HomeSectionRails from '@/components/home/HomeSectionRails';

const HomeMacAppSection: React.FC = () => (
  <section aria-labelledby="mac-app-heading" className="bg-white">
    <HomeSectionRails className="bg-white px-8 py-28 lg:px-10 lg:py-40">
      <div className="max-w-4xl pl-12 sm:pl-16">
        <Link
          href="/mac"
          className="text-violet-500 flex items-center gap-0.5 mb-8 group"
        >
          <span className="font-medium">Mac App</span>
          <ChevronRightIcon className="size-5 group-hover:translate-x-1 transition-transform duration-150" />
        </Link>
        <h2
          id="mac-app-heading"
          className="max-w-6xl text-pretty text-3xl font-semibold leading-[1.05] tracking-[-0.04em] text-stone-950 sm:text-4xl lg:text-5xl"
        >
          Gertrude for <AnimatedMac />
        </h2>
        <p className="mt-4 max-w-2xl text-xl leading-8 text-stone-600">
          <strong className="font-semibold text-stone-950">
            Complete internet safety for Mac.
          </strong>
          {` `}
          Gertrude blocks internet access by default, then lets families approve only the
          websites and apps they need.
        </p>
      </div>
      <MacFeatureGallery />
      <MacAccountabilityFeature />
    </HomeSectionRails>
  </section>
);

export default HomeMacAppSection;

const macFeatures = [
  {
    image: `/home/mac-suspension-requests.png`,
    titleBackground: `/home/mac-suspension-requests-bg.png`,
    alt: `Gertrude suspension request duration picker`,
    title: `Suspension requests.`,
    description: `Request a temporary filter suspension for a parent to approve.`,
  },
  {
    image: `/home/mac-menu-transparency.png`,
    titleBackground: `/home/mac-menu-transparency-bg.png`,
    alt: `Gertrude menu showing filtering and monitoring status`,
    title: `Complete transparency.`,
    description: `See filtering and monitoring status right from the menu bar.`,
  },
  {
    image: `/home/mac-unlock-requests.png`,
    titleBackground: `/home/mac-unlock-requests-bg.png`,
    alt: `Gertrude blocked requests selected for an unlock request`,
    title: `Simple unlock requests.`,
    description: `Select blocked domains and ask a parent for access in seconds.`,
  },
];

const MacFeatureGallery: React.FC = () => (
  <div className="mt-24 grid gap-10 md:grid-cols-3 md:gap-6">
    {macFeatures.map((feature) => (
      <div key={feature.title}>
        <div className="relative rounded-2xl">
          <img
            src={feature.image}
            alt={feature.alt}
            className="aspect-[1800/1230] w-full object-cover absolute rounded-2xl opacity-50 blur-sm"
          />
          <img
            src={feature.image}
            alt={feature.alt}
            className="aspect-[1800/1230] w-full object-cover rounded-2xl relative"
          />
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0 rounded-2xl ring-1 ring-inset ring-black/10"
          />
        </div>
        <p className="mt-5 text-lg leading-7 text-stone-500">
          <strong className="relative inline-block font-semibold text-stone-950 mr-1.5">
            <span
              aria-hidden
              className="absolute inset-y-0 -inset-x-1 rounded-lg opacity-25"
              style={{
                backgroundImage: `url(${feature.titleBackground})`,
                backgroundPosition: `center`,
                backgroundSize: `cover`,
              }}
            />
            <span className="relative">{feature.title}</span>
          </strong>
          {` `}
          {feature.description}
        </p>
      </div>
    ))}
  </div>
);

const MacAccountabilityFeature: React.FC = () => (
  <div className="relative -mx-8 mt-28 aspect-video min-h-[52rem] w-[calc(100%+4rem)] sm:min-h-[52rem] lg:-mx-10 lg:w-[calc(100%+5rem)] xl:min-h-0">
    <img
      src="/home/ribbon.png"
      alt=""
      className="pointer-events-none absolute inset-0 size-full object-fill"
    />
    <p className="relative z-10 max-w-2xl py-8 pr-8 pl-20 text-lg leading-7 text-stone-600 sm:py-12 sm:pr-12 sm:pl-24 lg:py-16 lg:pr-16 lg:pl-[6.5rem]">
      <strong className="mb-2 block text-xl font-semibold text-stone-950">
        Accountability without hovering.
      </strong>
      Gertrude can capture regular screenshots and a record of keystrokes, so parents and
      accountability partners can review activity from their own device.
    </p>

    <div
      aria-hidden
      className="absolute right-4 bottom-6 z-10 w-[72%] sm:right-10 sm:bottom-8 sm:w-[64%] md:right-12 md:w-[60%] lg:right-52 lg:w-[46%] xl:w-[38%]"
      style={{
        transform: `perspective(700px) rotateX(11deg) rotateY(-8deg) rotateZ(10deg)`,
        transformOrigin: `center bottom`,
      }}
    >
      <div className="space-y-3">
        <MacActivityScreenshot src="/home/accountability-screenshot.png" time="9:30 AM" />

        <div className="relative pl-3.5">
          <div className="absolute inset-y-0 left-0 w-1 rounded-full bg-white" />
          <div className="absolute top-[1px] bottom-[1px] left-[1px] w-0.5 rounded-full bg-red-500" />
          <p
            className="mb-2 text-sm font-medium text-red-700"
            style={{
              WebkitTextStroke: `2px white`,
              paintOrder: `stroke fill`,
            }}
          >
            During suspension
          </p>
          <div className="space-y-3">
            <MacActivityKeylog />
            <MacActivityScreenshot
              src="/home/accountability-screenshot-programmer.png"
              time="9:44 AM"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
);

interface MacActivityScreenshotProps {
  src: string;
  time: string;
}

const MacActivityScreenshot: React.FC<MacActivityScreenshotProps> = ({ src, time }) => (
  <div className="w-full min-w-0 overflow-hidden rounded-xl border-0 bg-transparent shadow shadow-stone-300/30 backdrop-blur-sm">
    <div className="relative">
      <img src={src} alt="" className="block h-auto w-full rounded-t-xl opacity-90" />
      <div className="pointer-events-none absolute inset-x-[1px] top-[1px] bottom-0 rounded-t-[11.5px] border-x border-t border-white/50" />
      <div className="pointer-events-none absolute inset-x-0 top-0 bottom-0 rounded-t-[12px] border-x border-t border-black/30" />
    </div>
    <div className="h-px w-full shrink-0 bg-stone-200" />
    <div className="flex items-center justify-between gap-2 rounded-b-xl border-x border-b border-stone-200 bg-white/90 p-3 text-xs text-stone-600 backdrop-blur-sm">
      <span>{time}</span>
      <span className="flex items-center gap-1 font-medium text-stone-600">
        <FlagIcon className="size-3" />
        Flag
      </span>
    </div>
  </div>
);

const MacActivityKeylog: React.FC = () => (
  <div className="overflow-hidden rounded-xl border border-white/80 bg-white/90 shadow-[0_24px_55px_-30px_rgba(76,29,149,0.65)] backdrop-blur-sm ring-1 ring-black/5">
    <div className="bg-stone-100/90 px-3 py-2.5 font-mono text-[11px] leading-5 text-stone-700 sm:text-xs">
      <p>searched: minecraft server mods</p>
      <p>opened discord invite</p>
    </div>
    <div className="flex items-center justify-between border-t border-stone-200 px-3 py-2 text-[10px] text-stone-500 sm:text-[11px]">
      <span>
        9:42 AM · Typed in <strong className="font-semibold">Google Chrome</strong>
      </span>
      <span className="flex items-center gap-1 font-medium text-amber-800">
        <FlagIcon className="size-3 fill-amber-200" />
        Flagged
      </span>
    </div>
  </div>
);

const AnimatedMac: React.FC = () => {
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

  const letters = [`M`, `a`, `c`];
  const initialDelay = 300;
  const stagger = 80;
  return (
    <span ref={phraseRef}>
      {letters.map((letter, index) => (
        <span
          key={letter}
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
