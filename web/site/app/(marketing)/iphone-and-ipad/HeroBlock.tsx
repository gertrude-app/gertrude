'use client';

import React, { useEffect, useState } from 'react';
import { APP_STORE_URL, BlockedIcon } from './shared';
import DeviceMockupBlock from '@/components/DeviceMockupBlock';
import FancyLink from '@/components/FancyLink';

const HeroBlock: React.FC = () => (
  <DeviceMockupBlock
    background="gradient"
    devicePosition="right"
    deviceContent={<BlockedGifSearchScreen />}
    deviceBleeds
    className="!pt-32 sm:!pt-40 lg:!pt-44"
  >
    <span className="inline-flex items-center gap-2 bg-gradient-to-r from-green-600 to-emerald-500 px-4 py-2 rounded-full shadow-lg shadow-green-600/30 text-sm font-bold text-white tracking-wide mb-6">
      100% FREE
    </span>
    <h1 className="text-4xl xs:text-5xl md:text-6xl font-bold text-white mb-6 leading-tight">
      Block GIFs & Other Screen Time Loopholes
    </h1>
    <p className="text-lg xs:text-xl md:text-2xl text-white/80 leading-relaxed mb-8">
      Gertrude for iPhone & iPad adds the missing parental control features Screen Time
      should have included.
    </p>
    <div className="flex flex-wrap gap-4">
      <FancyLink type="link" href={APP_STORE_URL} size="lg" color="primary" inverted>
        Download Now&nbsp;&rarr;
      </FancyLink>
      <FancyLink
        type="link"
        href="/blog/how-parents-can-block-images-gif-search-ios-18"
        size="lg"
        color="secondary"
        inverted
        variant="flat"
      >
        Learn More
      </FancyLink>
    </div>
  </DeviceMockupBlock>
);

const SEARCH_TERMS = [`Bikini`, `Beer pong`, `Sexy`, `Taylor Swift`, `Weed`];

const BlockedGifSearchScreen: React.FC = () => {
  const [isVisible, setIsVisible] = useState(false);
  const [termIndex, setTermIndex] = useState(0);
  const [showSquares, setShowSquares] = useState(false);
  const [typedChars, setTypedChars] = useState(0);
  const [cycleCount, setCycleCount] = useState(0);

  const searchText = SEARCH_TERMS[termIndex] ?? ``;
  const baseDelay = 800;
  const slideUpDelay = baseDelay;
  const typingStartDelay = baseDelay + 400;
  const typingSpeed = 150;
  const squaresDelay = 400;
  const displayDuration = 4000;
  const pauseDuration = 2500;

  useEffect(() => {
    const timer = setTimeout(() => setIsVisible(true), 300);
    return () => clearTimeout(timer);
  }, [cycleCount]);

  useEffect(() => {
    if (!isVisible) return;

    setTypedChars(0);
    setShowSquares(false);

    const typeNextChar = (charIndex: number): void => {
      if (charIndex <= searchText.length) {
        setTimeout(
          () => {
            setTypedChars(charIndex);
            if (charIndex < searchText.length) {
              typeNextChar(charIndex + 1);
            } else {
              setTimeout(() => setShowSquares(true), squaresDelay);
            }
          },
          charIndex === 0 ? typingStartDelay : typingSpeed,
        );
      }
    };

    typeNextChar(0);

    const cycleDuration =
      typingStartDelay + searchText.length * typingSpeed + squaresDelay + displayDuration;
    const cycleTimer = setTimeout(() => {
      const nextIndex = (termIndex + 1) % SEARCH_TERMS.length;
      if (nextIndex === 0) {
        setIsVisible(false);
        setTimeout(() => {
          setTermIndex(0);
          setCycleCount((c) => c + 1);
        }, 500 + pauseDuration);
      } else {
        setTermIndex(nextIndex);
      }
    }, cycleDuration);

    return () => clearTimeout(cycleTimer);
  }, [isVisible, termIndex, searchText.length, typingStartDelay]);

  return (
    <div className="size-full flex flex-col overflow-hidden relative bg-slate-900">
      <div className="absolute top-[25%] left-1/2 -translate-x-1/2 flex flex-col items-center gap-3">
        <img
          src="/gertrude-icon.png"
          alt="Gertrude app icon"
          width={80}
          height={80}
          className="size-20 rounded-2xl shadow-2xl ring-1 ring-white/10"
        />
        <span className="text-white/60 text-xs font-medium tracking-wide">
          Protected by Gertrude
        </span>
      </div>
      <div className="h-28 shrink-0" />
      <div
        className={`flex-1 bg-white flex flex-col rounded-t-2xl shadow-2xl ${isVisible ? `translate-y-0` : `translate-y-full`}`}
        style={{
          transition: `transform 0.5s cubic-bezier(0.22, 1.1, 0.36, 1)`,
          transitionDelay: isVisible ? `${slideUpDelay}ms` : `0ms`,
        }}
      >
        <div className="bg-gray-50 px-3 py-2.5 border-b border-gray-200 flex flex-col justify-center gap-2">
          <div className="flex items-center gap-2">
            <div className="flex-1 bg-gray-200/70 rounded-full px-3 py-1.5 flex items-center gap-2">
              <svg
                className="size-4 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
              <span className="text-gray-700 text-sm font-medium inline-flex items-center h-5">
                <span>{searchText.slice(0, typedChars)}</span>
                <span
                  className={`w-0.5 h-4 bg-blue-500 ml-px ${isVisible ? `animate-pulse` : `opacity-0`}`}
                />
              </span>
            </div>
            <span className="text-blue-500 text-sm font-medium">Cancel</span>
          </div>
          <div className="flex gap-2 text-xs font-medium">
            <span className="px-3 py-1 rounded-full bg-red-600 text-white">#images</span>
            <span className="px-3 py-1 rounded-full bg-gray-200 text-gray-500">
              Trending
            </span>
            <span className="px-3 py-1 rounded-full bg-gray-200 text-gray-500">
              Reactions
            </span>
          </div>
        </div>
        <div className="flex-1 p-2 overflow-hidden bg-gray-100">
          <div className="grid grid-cols-3 gap-1.5">
            {[...Array(18)].map((_, i) => (
              <div
                key={i}
                className={`aspect-square rounded-lg relative flex items-center justify-center bg-gray-300 shadow-inner transition-all duration-200 ${showSquares ? `opacity-100 scale-100` : `opacity-0 scale-90`}`}
                style={{
                  transitionDelay: showSquares ? `${i * 40}ms` : `0ms`,
                }}
              >
                <BlockedIcon className="size-7 text-red-400/50" />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default HeroBlock;
