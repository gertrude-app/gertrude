import { ChevronRightIcon, DownloadIcon, FlagIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import HomeFeatureCaption from '@/components/home/HomeFeatureCaption';
import HomeLetterRipple from '@/components/home/HomeLetterRipple';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { freeTrialDays, pricingPlans } from '@/lib/pricing';

const HomeMacAppSection: React.FC = () => (
  <section aria-labelledby="mac-app-heading" className="bg-white">
    <HomeSectionRails className="bg-white px-8 py-20 sm:py-28 lg:px-10 lg:py-40">
      <div className="max-w-4xl sm:pl-6 lg:pl-16">
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
          Gertrude for <HomeLetterRipple text="Mac" />
        </h2>
        <p className="mt-4 max-w-2xl text-lg leading-7 text-stone-600 sm:text-xl sm:leading-8">
          <strong className="font-semibold text-stone-950">
            Everything blocked, except what you approve.
          </strong>
          {` `}
          Gertrude blocks the entire internet on a Mac, then unlocks only the websites and
          apps you choose.
        </p>
      </div>
      <MacFeatureGallery />
      <MacAccountabilityFeature />
      <div className="mx-auto mt-20 max-w-2xl text-center">
        <h3 className="text-2xl font-semibold tracking-[-0.025em] text-stone-950">
          Free to start.
        </h3>
        <p className="mt-3 text-pretty text-lg leading-7 text-stone-600">
          Try Gertrude for Mac free for {freeTrialDays.mac} days, no credit card required.
          After that, it’s ${pricingPlans.full.priceDollars} a month for your whole
          family, with Gertrude Blocker, Music, and Podcasts included.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-3">
          <HomeButtonLink href="/mac" size="hero" variant="secondary">
            Learn more
            <ChevronRightIcon className="size-4" />
          </HomeButtonLink>
          <HomeButtonLink href="/download-mac-app" size="hero" variant="primary">
            Download
            <DownloadIcon className="size-4" />
          </HomeButtonLink>
        </div>
      </div>
    </HomeSectionRails>
  </section>
);

export default HomeMacAppSection;

const macFeatures = [
  {
    image: `/home/mac-suspension-requests.webp`,
    imageSrcSet: `/home/mac-suspension-requests-900.webp 900w, /home/mac-suspension-requests-1200.webp 1200w, /home/mac-suspension-requests-1440.webp 1440w, /home/mac-suspension-requests.webp 1800w`,
    titleBackground: `/home/mac-suspension-requests-bg.webp`,
    alt: `Gertrude suspension request duration picker`,
    title: `Temporary access, with oversight.`,
    description: `When they need something that isn’t normally allowed, they can ask for temporary access. Monitoring stays on, and the filter turns back on by itself.`,
  },
  {
    image: `/home/mac-menu-transparency.webp`,
    imageSrcSet: `/home/mac-menu-transparency-900.webp 900w, /home/mac-menu-transparency-1200.webp 1200w, /home/mac-menu-transparency-1440.webp 1440w, /home/mac-menu-transparency.webp 1800w`,
    titleBackground: `/home/mac-menu-transparency-bg.webp`,
    alt: `Gertrude menu showing filtering and monitoring status`,
    title: `Honest by design.`,
    description: `They can always see that the filter is on and what’s being recorded, right from the menu bar. No hidden spying.`,
  },
  {
    image: `/home/mac-unlock-requests.webp`,
    imageSrcSet: `/home/mac-unlock-requests-900.webp 900w, /home/mac-unlock-requests-1200.webp 1200w, /home/mac-unlock-requests-1440.webp 1440w, /home/mac-unlock-requests.webp 1800w`,
    titleBackground: `/home/mac-unlock-requests-bg.webp`,
    alt: `Gertrude blocked requests selected for an unlock request`,
    title: `Strict, not frustrating.`,
    description: `If a site they need is blocked, they can send you a request straight from their Mac. You get a notification and can unlock it from anywhere.`,
  },
];

const macFeatureImageSizes = `(min-width: 1280px) 384px, (min-width: 768px) calc((100vw - 10rem) / 3), calc(100vw - 4rem)`;

const MacFeatureGallery: React.FC = () => (
  <div className="mt-12 grid gap-10 sm:mt-16 md:grid-cols-3 md:gap-6 lg:mt-24">
    {macFeatures.map((feature) => (
      <div key={feature.title}>
        <div className="relative rounded-2xl">
          <img
            src={feature.image}
            srcSet={feature.imageSrcSet}
            sizes={macFeatureImageSizes}
            alt=""
            width={1800}
            height={1230}
            loading="lazy"
            decoding="async"
            className="aspect-[1800/1230] w-full object-cover absolute rounded-2xl opacity-50 blur-sm"
          />
          <img
            src={feature.image}
            srcSet={feature.imageSrcSet}
            sizes={macFeatureImageSizes}
            alt={feature.alt}
            width={1800}
            height={1230}
            loading="lazy"
            decoding="async"
            className="aspect-[1800/1230] w-full object-cover rounded-2xl relative"
          />
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0 rounded-2xl ring-1 ring-inset ring-black/10"
          />
        </div>
        <HomeFeatureCaption
          title={feature.title}
          description={feature.description}
          backgroundImage={feature.titleBackground}
        />
      </div>
    ))}
  </div>
);

const MacAccountabilityFeature: React.FC = () => (
  <div className="relative -mx-8 mt-16 w-[calc(100%+4rem)] pb-12 max-xl:overflow-hidden sm:mt-24 lg:-mx-10 lg:w-[calc(100%+5rem)] xl:mt-28 xl:aspect-video xl:pb-0">
    <img
      src="/home/ribbon.webp"
      srcSet="/home/ribbon-800.webp 800w, /home/ribbon-1200.webp 1200w, /home/ribbon-1600.webp 1600w, /home/ribbon-2560.webp 2560w, /home/ribbon.webp 4000w"
      sizes="(min-width: 1280px) 1280px, 100vw"
      alt=""
      width={4000}
      height={2800}
      loading="lazy"
      decoding="async"
      className="pointer-events-none absolute inset-0 size-full object-fill"
    />
    <p className="relative z-10 max-w-2xl px-8 py-8 text-base leading-7 text-stone-600 sm:px-12 sm:py-12 sm:text-lg xl:py-16 xl:pr-16 xl:pl-[6.5rem]">
      <strong className="mb-2 block text-xl font-semibold text-stone-950">
        Accountability without hovering.
      </strong>
      Gertrude can capture regular screenshots and everything typed, so parents and
      accountability partners can review activity on their own time. Activity during
      temporary access is highlighted, and you can flag anything worth a conversation.
    </p>

    <div
      aria-hidden
      className="relative z-10 mx-auto mt-8 w-[78%] max-w-md [transform:rotate(3deg)] sm:mt-10 sm:w-[64%] xl:absolute xl:right-52 xl:bottom-8 xl:mt-0 xl:w-[38%] xl:max-w-none xl:[transform:perspective(700px)_rotateX(11deg)_rotateY(-8deg)_rotateZ(10deg)]"
      style={{
        transformOrigin: `center bottom`,
      }}
    >
      <div className="space-y-3">
        <MacActivityScreenshot
          src="/home/accountability-screenshot.webp"
          srcSet="/home/accountability-screenshot-800.webp 800w, /home/accountability-screenshot-1000.webp 1000w, /home/accountability-screenshot-1200.webp 1200w, /home/accountability-screenshot.webp 1600w"
          width={1600}
          height={983}
          time="9:30 AM"
        />

        <div className="relative pb-5 pl-3.5">
          <div className="pointer-events-none absolute bottom-0 left-0 top-2.5 flex w-8 flex-col drop-shadow-[0_0_1px_white]">
            <div className="-mb-px h-5 w-5 shrink-0 rounded-tl-full border-t-[3px] border-l-[3px] border-red-600" />
            <div className="w-[3px] flex-1 bg-red-600" />
            <div className="-mt-px h-5 w-8 shrink-0 rounded-bl-full border-b-[3px] border-l-[3px] border-red-600" />
          </div>
          <p className="relative mb-2 ml-3.5 text-sm font-medium text-red-700 [text-shadow:0_0_1px_white,0_0_2px_white,0_0_4px_white]">
            During suspension
          </p>
          <div className="space-y-3">
            <MacActivityKeylog />
            <MacActivityScreenshot
              src="/home/accountability-screenshot-programmer.webp"
              srcSet="/home/accountability-screenshot-programmer-800.webp 800w, /home/accountability-screenshot-programmer-1000.webp 1000w, /home/accountability-screenshot-programmer-1200.webp 1200w, /home/accountability-screenshot-programmer.webp 1586w"
              width={1586}
              height={992}
              time="9:44 AM"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
);

const macActivityScreenshotSizes = `(min-width: 1280px) 486px, (min-width: 1024px) 46vw, (min-width: 768px) 60vw, (min-width: 640px) 64vw, 72vw`;

interface MacActivityScreenshotProps {
  src: string;
  srcSet: string;
  width: number;
  height: number;
  time: string;
}

const MacActivityScreenshot: React.FC<MacActivityScreenshotProps> = ({
  src,
  srcSet,
  width,
  height,
  time,
}) => (
  <div className="w-full min-w-0 overflow-hidden rounded-xl border-0 bg-transparent shadow shadow-stone-300/30 backdrop-blur-sm">
    <div className="relative">
      <img
        src={src}
        srcSet={srcSet}
        sizes={macActivityScreenshotSizes}
        alt=""
        width={width}
        height={height}
        loading="lazy"
        decoding="async"
        className="block h-auto w-full rounded-t-xl opacity-90"
      />
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
