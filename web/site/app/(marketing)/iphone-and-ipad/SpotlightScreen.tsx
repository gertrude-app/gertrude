'use client';

import React, { useEffect, useState } from 'react';
import { BlockedIcon } from './shared';

const SEARCH_TERMS = [`Bikini`, `Sexy`, `Beer pong`, `Vaping`, `Drunk`, `Weed`];

const SpotlightScreen: React.FC = () => {
  const [termIndex, setTermIndex] = useState(0);
  const [displayedText, setDisplayedText] = useState(``);
  const [resultsTerm, setResultsTerm] = useState(SEARCH_TERMS[0] ?? ``);
  const [showResults, setShowResults] = useState(false);

  const searchText = SEARCH_TERMS[termIndex] ?? ``;
  const typingSpeed = 120;
  const resultsDelay = 300;
  const displayDuration = 5000;

  useEffect(() => {
    setDisplayedText(``);
    setShowResults(false);

    const typeNextChar = (charIndex: number): void => {
      if (charIndex <= searchText.length) {
        setTimeout(
          () => {
            setDisplayedText(searchText.slice(0, charIndex));
            if (charIndex < searchText.length) {
              typeNextChar(charIndex + 1);
            } else {
              setTimeout(() => {
                setResultsTerm(searchText);
                setShowResults(true);
              }, resultsDelay);
            }
          },
          charIndex === 0 ? 400 : typingSpeed,
        );
      }
    };

    typeNextChar(0);

    const cycleDuration =
      400 + searchText.length * typingSpeed + resultsDelay + displayDuration;
    const cycleTimer = setTimeout(() => {
      setTermIndex((prev) => (prev + 1) % SEARCH_TERMS.length);
    }, cycleDuration);

    return () => clearTimeout(cycleTimer);
  }, [termIndex, searchText]);

  return (
    <div className="size-full flex flex-col relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-br from-slate-600 via-purple-900/50 to-slate-800" />
      <div className="absolute inset-0 backdrop-blur-xl bg-black/30" />
      <div className="relative flex-1 flex flex-col pt-14 px-4">
        <div className="bg-white/20 backdrop-blur-md rounded-xl px-3 py-2 flex items-center gap-2 mb-4">
          <svg
            className="size-4 text-white/60"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <circle cx="11" cy="11" r="8" />
            <path d="M21 21l-4.35-4.35" />
          </svg>
          <span className="text-white text-sm font-normal flex items-center h-5">
            {displayedText}
            <span className="w-0.5 h-4 bg-white ml-px animate-pulse" />
          </span>
          <div className="ml-auto">
            <svg className="size-4 text-white/40" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 15c1.66 0 3-1.34 3-3V6c0-1.66-1.34-3-3-3S9 4.34 9 6v6c0 1.66 1.34 3 3 3zm5-3c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-2.08c3.39-.49 6-3.39 6-6.92h-2z" />
            </svg>
          </div>
        </div>
        <div
          className={`flex-1 overflow-hidden transition-opacity duration-300 ${
            showResults ? `opacity-100` : `opacity-0`
          }`}
        >
          <div className="mb-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-white font-semibold text-sm">Web Images</span>
              <span className="text-white/50 text-xs">Show More</span>
            </div>
            <div className="grid grid-cols-4 gap-1">
              {[...Array(8)].map((_, i) => (
                <div
                  key={i}
                  className={`aspect-square bg-slate-500/50 rounded-lg flex items-center justify-center transition-all duration-200 ${
                    showResults ? `opacity-100 scale-100` : `opacity-0 scale-90`
                  }`}
                  style={{ transitionDelay: showResults ? `${i * 50}ms` : `0ms` }}
                >
                  <BlockedIcon className="size-5 text-red-400/70" />
                </div>
              ))}
            </div>
            <p className="text-center text-white/40 text-[10px] mt-2">
              Blocked by Gertrude
            </p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3 mb-3">
            <div className="flex items-center justify-between mb-2">
              <span className="text-white font-semibold text-sm">Siri Knowledge</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="size-12 bg-slate-500/50 rounded-lg flex items-center justify-center shrink-0">
                <BlockedIcon className="size-6 text-red-400/70" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-white font-medium text-sm">{resultsTerm}</p>
                <p className="text-white/50 text-xs truncate">Search result blocked</p>
              </div>
              <svg
                className="size-4 text-white/30"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M8.59 16.59L13.17 12 8.59 7.41 10 6l6 6-6 6-1.41-1.41z" />
              </svg>
            </div>
            <div className="mt-3 space-y-1.5">
              <div className="h-2 bg-white/20 rounded w-full" />
              <div className="h-2 bg-white/20 rounded w-full" />
              <div className="h-2 bg-white/20 rounded w-full" />
              <div className="h-2 bg-white/20 rounded w-[60%]" />
            </div>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-3">
            <div className="flex items-center justify-between mb-2">
              <span className="text-white font-semibold text-sm">App Store</span>
              <span className="text-white/50 text-xs">Search in App</span>
            </div>
            <div className="flex items-center gap-3">
              <div className="size-10 bg-slate-700 rounded-xl flex items-center justify-center">
                <span className="text-white text-[8px] font-bold">APP</span>
              </div>
              <div className="flex-1">
                <p className="text-white text-sm">Related App</p>
                <p className="text-white/40 text-xs">Entertainment</p>
              </div>
              <div className="bg-white/20 rounded-full px-3 py-1">
                <span className="text-white text-xs font-semibold">GET</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SpotlightScreen;
