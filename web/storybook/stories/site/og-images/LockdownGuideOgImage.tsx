import React from 'react';
import {
  AppleMapsBlockingScreen,
  BottomMetaRow,
  GifBlockingScreen,
  OgFrame,
  PhoneFrame,
  SpotifyBlockingScreen,
  SpotlightBlockingScreen,
} from './OgParts';

const LockdownGuideOgImage: React.FC = () => (
  <OgFrame
    bgGradient="radial-gradient(ellipse at 50% 120%, #4c1d95 0%, #1e1b4b 45%, #09090b 85%)"
    pinstripeRgb="255,255,255"
    bottomMaskHeightClass="h-48"
    bottomMaskOpacity={0.9}
  >
    <div className="absolute top-14 left-0 right-0 z-20 flex flex-col items-center">
      <span className="inline-flex items-center gap-2.5 bg-violet-500/20 backdrop-blur-sm border border-violet-300/30 px-4 py-1 rounded-full text-violet-200 text-[12px] font-bold tracking-[0.3em] uppercase mb-4">
        The Definitive Guide
      </span>
      <h1 className="text-[68px] font-bold text-white leading-[1] tracking-tight text-center">
        Lock down your kid
        <span
          style={{
            fontFamily: `Palatino, "Palatino Linotype", serif`,
            fontSize: `0.95em`,
            marginRight: `-0.12em`,
          }}
        >
          &rsquo;
        </span>
        s{` `}
        <span
          className="bg-gradient-to-r from-violet-300 via-fuchsia-300 to-pink-300 bg-clip-text text-transparent"
          style={{ WebkitBackgroundClip: `text` }}
        >
          iPhone
        </span>
      </h1>
    </div>

    <div className="absolute bottom-0 left-0 right-0 h-[420px] flex items-end justify-center gap-8 px-8">
      <div className="relative translate-y-10">
        <PhoneFrame className="w-[200px] h-[410px] -rotate-[8deg]">
          <SpotifyBlockingScreen />
        </PhoneFrame>
        <ScreenLabel text="Spotify artwork" rotateDeg={-8} offsetX={-36} />
      </div>

      <div className="relative z-10 translate-y-8">
        <PhoneFrame className="w-[220px] h-[450px]">
          <GifBlockingScreen searchText="Bikini" />
        </PhoneFrame>
        <ScreenLabel text="#images GIFs" highlight />
      </div>

      <div className="relative translate-y-8 -translate-x-2">
        <PhoneFrame className="w-[200px] h-[410px] rotate-[6deg]">
          <SpotlightBlockingScreen />
        </PhoneFrame>
        <ScreenLabel text="Spotlight search" rotateDeg={6} offsetX={22} />
      </div>

      <div className="relative translate-y-20 -translate-x-6">
        <PhoneFrame className="w-[180px] h-[370px] rotate-[12deg]">
          <AppleMapsBlockingScreen />
        </PhoneFrame>
        <ScreenLabel text="Maps photos" rotateDeg={12} offsetX={44} offsetY={6} />
      </div>
    </div>

    <BottomMetaRow items={[`Every loophole`, `Every setting`, `Step by step`]} />
  </OgFrame>
);

const ScreenLabel: React.FC<{
  text: string;
  highlight?: boolean;
  rotateDeg?: number;
  offsetX?: number;
  offsetY?: number;
}> = ({ text, highlight, rotateDeg = 0, offsetX = 0, offsetY = 0 }) => (
  <div
    className={`absolute left-1/2 px-2.5 py-0.5 rounded-full text-[10px] font-bold tracking-wider uppercase whitespace-nowrap ${
      highlight
        ? `bg-gradient-to-r from-fuchsia-500 to-pink-500 text-white shadow-lg shadow-fuchsia-500/40`
        : `bg-white/10 border border-white/20 text-white/70 backdrop-blur-sm`
    }`}
    style={{
      top: `${-12 + offsetY}px`,
      transform: `translateX(calc(-50% + ${offsetX}px)) rotate(${rotateDeg}deg)`,
    }}
  >
    {text}
  </div>
);

export default LockdownGuideOgImage;
