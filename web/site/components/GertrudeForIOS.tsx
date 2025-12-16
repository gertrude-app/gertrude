'use client';

import { ExternalLinkIcon, StarIcon } from 'lucide-react';
import React, { useRef } from 'react';
import AnimatedUnderline from './AnimatedUnderline';
import FancyLink from './FancyLink';
import Phone from './super-scroller-illustration/Phone';
import { useIntersectionVisibility, useScrollProgress } from '@/lib/hooks';

const GertrudeForIOS: React.FC = () => {
  const wrapperRef = useRef<HTMLDivElement>(null);
  const stickyRef = useRef<HTMLDivElement>(null);
  const isVisible = useIntersectionVisibility(stickyRef, 0.5);
  const exitProgress = useScrollProgress(wrapperRef);

  const reviewStartProgress = 0.32;
  const reviewEndProgress = 0.92;
  const reviewRange = reviewEndProgress - reviewStartProgress;
  const progressPerReview = reviewRange / REVIEWS.length;
  const currentReview = Math.min(
    REVIEWS.length - 1,
    Math.max(0, Math.floor((exitProgress - reviewStartProgress) / progressPerReview)),
  );

  return (
    <div id="ios" ref={wrapperRef} className="h-[650vh] relative">
      <section
        ref={stickyRef}
        className="sticky top-0 min-h-screen bg-gradient-to-tl from-white via-white via-55% to-fuchsia-200 overflow-hidden"
      >
        <div
          className="absolute inset-0 bg-gradient-to-b from-fuchsia-900 to-violet-950 pointer-events-none z-10"
          style={{
            opacity: Math.min(1, Math.max(0, (exitProgress - 0.18) / 0.1)) * 0.95,
          }}
        />

        <div
          className="absolute inset-0 z-20 flex items-center justify-center pointer-events-none"
          style={{
            opacity: Math.min(1, Math.max(0, (exitProgress - 0.22) / 0.08)),
          }}
        >
          <div
            className="max-w-2xl mx-4 pointer-events-auto relative"
            style={{
              transform: `translateY(${Math.max(0, 1 - (exitProgress - 0.22) / 0.1) * 60}px)`,
            }}
          >
            <div className="text-center mb-6 xs:mb-12">
              <a
                href="https://apps.apple.com/us/app/gertrude-blocker/id6736368820?see-all=reviews&platform=iphone"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 text-fuchsia-300/60 text-xs xs:text-sm font-semibold tracking-wider uppercase hover:text-fuchsia-200 transition-colors duration-200"
              >
                More App Store Reviews
                <ExternalLinkIcon className="size-3 xs:size-3.5" />
              </a>
            </div>

            <div className="relative overflow-hidden w-screen left-1/2 -translate-x-1/2">
              <div
                className="flex transition-transform duration-500 ease-out"
                style={{ transform: `translateX(-${currentReview * 100}%)` }}
              >
                {REVIEWS.map((review, i) => (
                  <div key={i} className="w-screen shrink-0 flex justify-center">
                    <div className="max-w-2xl text-center px-6 xs:px-8">
                      <h3 className="text-lg xs:text-2xl md:text-3xl font-bold text-white mb-2 xs:mb-4 uppercase">
                        {review.title}
                      </h3>
                      <div
                        className="flex items-center justify-center gap-1 mb-4 xs:mb-8"
                        role="img"
                        aria-label="5 out of 5 stars"
                      >
                        {[...Array(5)].map((_, j) => (
                          <StarIcon
                            key={j}
                            className="size-4 xs:size-[22px] fill-amber-400 text-amber-400"
                            strokeWidth={0}
                            aria-hidden="true"
                          />
                        ))}
                      </div>
                      <p className="text-fuchsia-100 text-xl xs:text-3xl md:text-4xl leading-snug xs:leading-relaxed mb-8 xs:mb-16 font-serif">
                        &ldquo;{review.text}&rdquo;
                      </p>
                      <p className="text-fuchsia-300/60 text-sm xs:text-base">
                        {review.date} — {review.author}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div
            className="absolute bottom-8 left-0 right-0 flex items-center justify-center gap-2 pointer-events-none"
            style={{
              opacity: Math.min(1, Math.max(0, (exitProgress - 0.22) / 0.08)),
            }}
          >
            {REVIEWS.map((_, i) => (
              <div
                key={i}
                className={`size-1.5 rounded-full transition-all duration-300 ${
                  i === currentReview ? `bg-fuchsia-300` : `bg-fuchsia-300/30`
                }`}
              />
            ))}
          </div>
        </div>
        <div
          className="min-h-screen flex flex-col items-center justify-center md+:pr-16 xl:pr-24"
          style={{
            filter: `blur(${Math.max(0, (exitProgress - 0.15) / 0.2) * 8}px)`,
          }}
        >
          <div className="max-w-6xl w-full py-12 xs:py-14 md:py-16 md+:py-10 relative">
            <div className="md+:hidden relative h-[140px] [@media(min-height:700px)]:h-[260px] xs:h-[300px] overflow-hidden flex items-start justify-center -mt-4 [@media(min-height:700px)]:-mt-8 mb-4 xs:mb-8">
              <div className="absolute inset-0 bg-gradient-to-b from-transparent via-fuchsia-100/40 to-violet-200/60" />
              <div
                className={`${isVisible && exitProgress === 0 ? `translate-y-0 opacity-100` : !isVisible ? `translate-y-12 opacity-0` : ``}`}
                style={{
                  transition: `all 0.6s cubic-bezier(0.2, 1.4, 0.5, 1)`,
                  transitionDelay: isVisible && exitProgress === 0 ? `600ms` : `0ms`,
                  ...(exitProgress > 0.08 && {
                    transform: `translateY(${((exitProgress - 0.08) / 0.25) * 100}px)`,
                    opacity: 1 - (exitProgress - 0.08) / 0.25,
                  }),
                }}
              >
                <Phone
                  className="shadow-2xl scale-[0.55] [@media(min-height:700px)]:scale-[0.65] xs:scale-[0.85] -mt-32 [@media(min-height:700px)]:-mt-24 xs:mt-0"
                  labelStatus="hidden"
                >
                  <BlockedGifSearchScreen isVisible={isVisible} />
                </Phone>
              </div>
            </div>

            <div className="grid grid-cols-1 md+:grid-cols-12 gap-12 md+:gap-16 xl:gap-20 items-center px-6 xs:px-8 sm:px-12 md:px-20 pt-4 xs:pt-6">
              <div className="md+:order-1 md+:col-span-9 relative z-10 flex flex-col items-center xs:items-start">
                <div className="relative inline-block mb-3 xs:mb-6">
                  <div
                    className={`inline-flex items-center gap-2 bg-gradient-to-r from-green-600 to-emerald-500 px-3 xs:px-4 py-1.5 xs:py-2 rounded-full shadow-lg shadow-green-600/30 ${isVisible && exitProgress === 0 ? `translate-x-0` : !isVisible ? `-translate-x-[500px]` : ``}`}
                    style={{
                      transition: `transform 0.25s cubic-bezier(0.2, 1.4, 0.5, 1)`,
                      transitionDelay: isVisible && exitProgress === 0 ? `1000ms` : `0ms`,
                      animation: isVisible
                        ? `waggle-badge 0.5s ease-in-out 1.35s`
                        : `none`,
                      ...(exitProgress > 0.08 && {
                        transform: `translateX(${(-(exitProgress - 0.08) / 0.25) * 300}px)`,
                        opacity: 1 - (exitProgress - 0.08) / 0.25,
                      }),
                    }}
                  >
                    <span className="text-xs xs:text-sm font-bold text-white tracking-wide">
                      100% FREE
                    </span>
                  </div>
                </div>

                <h2
                  className={`text-2xl xs:text-4xl md:text-5xl font-bold text-slate-900 mb-1 xs:mb-4 sm:mb-6 leading-tight text-center xs:text-left transition-all duration-500 ${
                    isVisible && exitProgress === 0
                      ? `translate-x-0 opacity-100`
                      : !isVisible
                        ? `-translate-x-24 opacity-0`
                        : ``
                  }`}
                  style={{
                    transitionDelay: isVisible && exitProgress === 0 ? `400ms` : `0ms`,
                    ...(exitProgress > 0.08 && {
                      transform: `translateX(${(-(exitProgress - 0.08) / 0.25) * 100}px)`,
                      opacity: 1 - (exitProgress - 0.08) / 0.25,
                    }),
                  }}
                >
                  Gertrude for iPhone & iPad
                </h2>

                <div
                  className={`flex items-center gap-3 mb-6 justify-center xs:justify-start w-full transition-all duration-500 ${
                    isVisible && exitProgress === 0
                      ? `translate-x-0 opacity-100`
                      : !isVisible
                        ? `translate-x-24 opacity-0`
                        : ``
                  }`}
                  style={{
                    transitionDelay: isVisible && exitProgress === 0 ? `600ms` : `0ms`,
                    ...(exitProgress > 0.08 && {
                      transform: `translateX(${((exitProgress - 0.08) / 0.25) * 100}px)`,
                      opacity: 1 - (exitProgress - 0.08) / 0.25,
                    }),
                  }}
                >
                  <div
                    className="flex items-center gap-0.5"
                    role="img"
                    aria-label="4.9 out of 5 stars"
                  >
                    {[...Array(5)].map((_, i) => (
                      <StarIcon
                        key={i}
                        className="size-4 xs:size-5 fill-amber-400 text-amber-400"
                        strokeWidth={0}
                        aria-hidden="true"
                      />
                    ))}
                  </div>
                  <div className="flex items-center gap-1.5 xs:gap-2 text-slate-700">
                    <span className="text-base xs:text-xl font-bold">4.9</span>
                    <span className="text-[0.65rem] xs:text-sm">App Store</span>
                  </div>
                </div>

                <p
                  className={`text-base xs:text-xl sm:text-2xl text-slate-600 leading-relaxed mb-6 xs:mb-8 transition-all duration-500 ${
                    isVisible && exitProgress === 0
                      ? `translate-x-0 opacity-100`
                      : !isVisible
                        ? `-translate-x-24 opacity-0`
                        : ``
                  }`}
                  style={{
                    transitionDelay: isVisible && exitProgress === 0 ? `800ms` : `0ms`,
                    ...(exitProgress > 0.08 && {
                      transform: `translateX(${(-(exitProgress - 0.08) / 0.25) * 100}px)`,
                      opacity: 1 - (exitProgress - 0.08) / 0.25,
                    }),
                  }}
                >
                  The{` `}
                  <span className="relative inline-block">
                    missing features
                    <AnimatedUnderline
                      isVisible={isVisible}
                      delay={1400}
                      gradientId="ios-underline-gradient"
                      fromColor="#8b5cf6"
                      toColor="#d946ef"
                    />
                  </span>
                  {` `}
                  Screen Time should have included.
                </p>

                <ul
                  className={`w-full space-y-2 xs:space-y-3 mb-6 xs:mb-8 bg-white/60 backdrop-blur-sm p-4 xs:p-6 rounded-2xl border border-violet-100 md+:mr-4 transition-all duration-500 ${
                    isVisible && exitProgress === 0
                      ? `translate-y-0 opacity-100`
                      : !isVisible
                        ? `translate-y-12 opacity-0`
                        : ``
                  }`}
                  style={{
                    transitionDelay: isVisible && exitProgress === 0 ? `1000ms` : `0ms`,
                    ...(exitProgress > 0.08 && {
                      transform: `translateY(${((exitProgress - 0.08) / 0.25) * 50}px)`,
                      opacity: 1 - (exitProgress - 0.08) / 0.25,
                    }),
                  }}
                >
                  <Feature text="Block GIF searches in #images" />
                  <Feature text="Block spotlight internet & image search" />
                  <Feature text="Block album artwork in Spotify" />
                  <Feature text="Remove images from Apple Maps" />
                  <Feature text="Plus several more loopholes..." />
                </ul>

                <div
                  className={`flex items-center xs:items-start justify-center sm:justify-start gap-3 xs:gap-4 transition-all duration-500 ${
                    isVisible && exitProgress === 0
                      ? `translate-y-0 opacity-100`
                      : !isVisible
                        ? `translate-y-8 opacity-0`
                        : ``
                  }`}
                  style={{
                    transitionDelay: isVisible && exitProgress === 0 ? `1200ms` : `0ms`,
                    ...(exitProgress > 0.08 && {
                      transform: `translateY(${((exitProgress - 0.08) / 0.25) * 50}px)`,
                      opacity: 1 - (exitProgress - 0.08) / 0.25,
                    }),
                  }}
                >
                  <FancyLink
                    type="link"
                    href="https://apps.apple.com/us/app/gertrude-blocker/id6736368820"
                    size="sm"
                    color="primary"
                    className="xs:hidden"
                  >
                    Download&nbsp;&rarr;
                  </FancyLink>
                  <FancyLink
                    type="link"
                    href="https://apps.apple.com/us/app/gertrude-blocker/id6736368820"
                    size="lg"
                    color="primary"
                    className="hidden xs:inline-flex"
                  >
                    Download&nbsp;&rarr;
                  </FancyLink>
                  <FancyLink
                    type="link"
                    href="/blog/how-parents-can-block-images-gif-search-ios-18"
                    size="sm"
                    color="secondary"
                    className="xs:hidden"
                  >
                    Learn&nbsp;More
                  </FancyLink>
                  <FancyLink
                    type="link"
                    href="/blog/how-parents-can-block-images-gif-search-ios-18"
                    size="lg"
                    color="secondary"
                    className="hidden xs:inline-flex"
                  >
                    Learn&nbsp;More
                  </FancyLink>
                </div>
              </div>

              <div
                className={`hidden md+:block md+:order-2 md+:col-span-3 relative h-[500px] transition-all duration-500 ${
                  isVisible && exitProgress === 0
                    ? `translate-x-0 opacity-100`
                    : !isVisible
                      ? `translate-x-24 opacity-0`
                      : ``
                }`}
                style={{
                  transitionDelay: isVisible && exitProgress === 0 ? `600ms` : `0ms`,
                  ...(exitProgress > 0.08 && {
                    transform: `translateX(${((exitProgress - 0.08) / 0.25) * 150}px)`,
                    opacity: 1 - (exitProgress - 0.08) / 0.25,
                  }),
                }}
              >
                <div className="-ml-12 -mt-8">
                  <Phone className="shadow-2xl scale-[0.85]" labelStatus="hidden">
                    <BlockedGifSearchScreen isVisible={isVisible} />
                  </Phone>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

interface BlockedGifSearchScreenProps {
  isVisible: boolean;
}

const BlockedGifSearchScreen: React.FC<BlockedGifSearchScreenProps> = ({ isVisible }) => {
  const searchText = `Bikini`;
  const baseDelay = 2500;
  const slideUpDelay = baseDelay;
  const typingStartDelay = baseDelay + 400;
  const typingSpeed = 120;
  const squaresStartDelay = typingStartDelay + searchText.length * typingSpeed + 300;
  const squareStagger = 50;

  return (
    <div className="size-full flex flex-col overflow-hidden relative bg-slate-900">
      <div className="absolute top-[25%] left-1/2 -translate-x-1/2">
        <img
          src="/gertrude-icon.png"
          alt="Gertrude app icon"
          width={80}
          height={80}
          className="size-20 rounded-2xl shadow-lg"
        />
      </div>
      <div className="h-16 shrink-0" />
      <div
        className={`flex-1 bg-white flex flex-col ${isVisible ? `translate-y-0` : `translate-y-full`}`}
        style={{
          transition: `transform 0.5s cubic-bezier(0.22, 1.1, 0.36, 1)`,
          transitionDelay: isVisible ? `${slideUpDelay}ms` : `0ms`,
        }}
      >
        <div className="bg-gray-100 px-3 py-2 flex items-center gap-2">
          <div className="flex-1 bg-white rounded-lg px-3 py-2 flex items-center gap-2">
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
            <span className="text-gray-800 text-sm font-medium">
              {searchText.split(``).map((char, i) => (
                <span
                  key={i}
                  className={`inline-block ${isVisible ? `opacity-100` : `opacity-0`}`}
                  style={{
                    transition: `opacity 0.1s ease-out`,
                    transitionDelay: isVisible
                      ? `${typingStartDelay + i * typingSpeed}ms`
                      : `0ms`,
                  }}
                >
                  {char}
                </span>
              ))}
            </span>
          </div>
          <span className="text-blue-500 text-sm font-medium">Cancel</span>
        </div>
        <div className="flex-1 p-1.5 overflow-hidden">
          <div className="grid grid-cols-3 gap-1.5">
            {[...Array(18)].map((_, i) => (
              <div
                key={i}
                className={`aspect-square bg-gradient-to-br from-gray-200 to-gray-300 rounded relative flex items-center justify-center ${isVisible ? `opacity-100 scale-100` : `opacity-0 scale-75`}`}
                style={{
                  transition: `opacity 0.2s ease-out, transform 0.2s ease-out`,
                  transitionDelay: isVisible
                    ? `${squaresStartDelay + i * squareStagger}ms`
                    : `0ms`,
                }}
              >
                <svg
                  className="size-8 text-red-400/40"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth={2}
                >
                  <circle cx="12" cy="12" r="10" />
                  <line x1="4.93" y1="4.93" x2="19.07" y2="19.07" />
                </svg>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

interface FeatureProps {
  text: string;
}

const Feature: React.FC<FeatureProps> = ({ text }) => (
  <li className="flex items-start gap-2 xs:gap-3">
    <div className="shrink-0 size-4 xs:size-5 mt-0.5 rounded-md bg-gradient-to-br from-violet-500 to-fuchsia-500 flex items-center justify-center">
      <svg
        className="size-2.5 xs:size-3.5 text-white"
        fill="none"
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="3"
        viewBox="0 0 24 24"
        stroke="currentColor"
        aria-hidden="true"
      >
        <polyline points="20 6 9 17 4 12" />
      </svg>
    </div>
    <span className="text-sm xs:text-base text-slate-700">{text}</span>
  </li>
);

export default GertrudeForIOS;

const REVIEWS = [
  {
    title: `THANK YOU`,
    text: `Saved my young son from looking at porn through the maps app. You are a lifesaver.`,
    author: `GratefulMom55`,
    date: `Apr 25, 2025`,
  },
  {
    title: `GIF Blocker!`,
    text: `Finally a way to block GIFS!!! Thank you, thank you, thank you!!!`,
    author: `HAAS1988`,
    date: `May 30, 2025`,
  },
  {
    title: `An absolute blessing`,
    text: `Likely the greatest blessing an app has had on our lives.`,
    author: `Austin944`,
    date: `Sep 25, 2025`,
  },
];
