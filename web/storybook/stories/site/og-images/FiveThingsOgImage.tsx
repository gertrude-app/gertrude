import React from 'react';
import {
  AppleMapsBlockingScreen,
  BottomMetaRow,
  GifBlockingScreen,
  OgFrame,
  PhoneFrame,
  SafariInNotesBlockingScreen,
  SiriBlockingScreen,
  SpotlightBlockingScreen,
} from './OgParts';

const FiveThingsOgImage: React.FC = () => (
  <OgFrame
    bgGradient="radial-gradient(ellipse at 50% 115%, #7f1d1d 0%, #1c1917 45%, #09090b 85%)"
    pinstripeRgb="251,191,36"
    bottomMaskHeightClass="h-40"
    bottomMaskOpacity={0.85}
  >
    <div className="absolute top-10 left-0 right-0 z-20 flex flex-col items-center">
      <span className="inline-flex items-center gap-2.5 bg-amber-400/15 border border-amber-300/40 px-4 py-1 rounded-full text-amber-200 text-[12px] font-bold tracking-[0.3em] uppercase mb-3">
        Loopholes You Missed
      </span>
      <h1 className="text-[58px] font-bold text-white leading-[1] tracking-tight text-center">
        <span className="text-white/70 font-light">The </span>
        <span
          className="bg-gradient-to-r from-amber-200 via-rose-300 to-rose-500 bg-clip-text text-transparent"
          style={{ WebkitBackgroundClip: `text` }}
        >
          5 things
        </span>
        <span className="text-white/70 font-light"> you forgot</span>
      </h1>
      <p className="mt-1.5 text-[24px] font-light text-white/60 tracking-tight">
        locking down your kid&rsquo;s iPhone.
      </p>
    </div>

    <div className="absolute bottom-0 left-0 right-0 h-[400px] flex items-end justify-center gap-3 px-8">
      <div className="relative translate-y-8 -rotate-[10deg]">
        <PhoneFrame className="w-[170px] h-[345px]">
          <SafariInNotesBlockingScreen />
        </PhoneFrame>
        <NumberBadge n={4} />
      </div>

      <div className="relative translate-y-4 -rotate-[5deg]">
        <PhoneFrame className="w-[175px] h-[355px]">
          <AppleMapsBlockingScreen />
        </PhoneFrame>
        <NumberBadge n={2} />
      </div>

      <div className="relative z-10">
        <PhoneFrame className="w-[195px] h-[395px]">
          <GifBlockingScreen searchText="Bikini" />
        </PhoneFrame>
        <NumberBadge n={1} center />
      </div>

      <div className="relative translate-y-4 rotate-[5deg]">
        <PhoneFrame className="w-[175px] h-[355px]">
          <SpotlightBlockingScreen />
        </PhoneFrame>
        <NumberBadge n={3} />
      </div>

      <div className="relative translate-y-8 rotate-[10deg]">
        <PhoneFrame className="w-[170px] h-[345px]">
          <SiriBlockingScreen />
        </PhoneFrame>
        <NumberBadge n={5} />
      </div>
    </div>

    <BottomMetaRow
      items={[`Every loophole`, `Step-by-step fixes`, `Apple won’t tell you`]}
      className="bottom-5 gap-4 text-[13px]"
    />
  </OgFrame>
);

const NumberBadge: React.FC<{ n: number; center?: boolean }> = ({ n, center }) => (
  <span
    className={`absolute -top-4 left-1/2 -translate-x-1/2 z-40 inline-flex items-center justify-center size-9 rounded-full text-[15px] font-bold tabular-nums shadow-lg ${
      center
        ? `bg-gradient-to-br from-amber-300 to-rose-500 text-white shadow-rose-500/40`
        : `bg-white/10 border border-amber-300/50 text-amber-200 backdrop-blur-sm`
    }`}
  >
    {n}
  </span>
);

export default FiveThingsOgImage;
