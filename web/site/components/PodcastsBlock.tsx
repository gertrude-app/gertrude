'use client';

import {
  ExternalLinkIcon,
  HeadphonesIcon,
  LockKeyholeIcon,
  PauseIcon,
  PodcastIcon,
  RotateCcwIcon,
  RotateCwIcon,
  SearchXIcon,
  StarIcon,
} from 'lucide-react';
import React, { useEffect, useRef, useState } from 'react';
import Phone from './super-scroller-illustration/Phone';
import { useDelayedVisibility, useIntersectionVisibility } from '@/lib/hooks';

const PodcastsBlock: React.FC = () => {
  const sectionRef = useRef<HTMLElement>(null);
  const isVisible = useIntersectionVisibility(sectionRef, 0.5);

  return (
    <section
      id="podcasts"
      ref={sectionRef}
      className="min-h-screen bg-gradient-to-br from-violet-700 to-fuchsia-600 overflow-hidden flex flex-col"
    >
      <div className="px-6 sm:px-12 md:px-10 lg:px-20 pt-10 pb-6 xs:py-12 flex flex-col relative flex-1">
        <div className="[background:radial-gradient(#ffffff33,transparent_60%)] w-176 h-176 absolute -right-80 -top-80" />
        <div className="[background:radial-gradient(#ffffff22,transparent_70%)] w-176 h-176 absolute -left-80 -bottom-80" />

        <div className="max-w-6xl mx-auto relative flex-1 flex flex-col justify-center">
          <div className="text-center mb-4 xs:mb-8 md:mb-16">
            <div
              className={`flex items-center justify-center gap-3 xs:mb-6 transition-all duration-500 ${
                isVisible ? `translate-x-0 opacity-100` : `-translate-x-16 opacity-0`
              }`}
              style={{ transitionDelay: isVisible ? `800ms` : `0ms` }}
            >
              <PodcastIcon className="size-10 xs:size-12 md:size-14 text-orange-300 drop-shadow-[0_0_12px_rgba(253,186,116,0.5)]" />
              <h2 className="text-[2.75rem] xs:text-5xl md:text-7xl font-bold">
                <span className="bg-gradient-to-b from-white to-fuchsia-200 bg-clip-text text-transparent">
                  Gertrude
                </span>
                {` `}
                <span className="text-orange-300 tracking-tight sm:animate-[glow-pulse_3s_ease-in-out_infinite]">
                  AM
                </span>
              </h2>
              <img
                src="/docs/images/gertrude-am-radio.png"
                alt="Vintage radio representing Gertrude AM podcast app"
                width={80}
                height={80}
                className={`w-20 rounded-xl hidden md:block shadow-[0_8px_30px_rgba(0,0,0,0.4)] ml-5 transition-all duration-500 ${
                  isVisible ? `scale-100 opacity-100` : `scale-75 opacity-0`
                }`}
                style={{ transitionDelay: isVisible ? `600ms` : `0ms` }}
              />
            </div>
            <p
              className={`text-lg xs:text-xl md:text-3xl font-medium -mt-3 xs:-mt-1 md:mt-0 mb-3 transition-all duration-500 ${
                isVisible ? `translate-x-0 opacity-100` : `translate-x-16 opacity-0`
              }`}
              style={{ transitionDelay: isVisible ? `1000ms` : `0ms` }}
            >
              <span className="text-white/90">A Safe</span>
              {` `}
              <span className="bg-gradient-to-r from-orange-200 to-orange-400 bg-clip-text text-transparent font-bold">
                Podcast App
              </span>
              {` `}
              <span className="text-white/90">for Kids</span>
            </p>
            <p
              className={`hidden xs:block text-sm xs:text-base md:text-lg text-fuchsia-100/90 max-w-2xl mx-auto leading-snug transition-all duration-500 ${
                isVisible ? `translate-x-0 opacity-100` : `-translate-x-12 opacity-0`
              }`}
              style={{ transitionDelay: isVisible ? `1200ms` : `0ms` }}
            >
              PIN-protected content control. Kids only listen to shows you approve.
            </p>
          </div>

          <div className="grid md:grid-cols-[1fr_3fr] lg:grid-cols-[2fr_3fr] gap-8 md:gap-10 lg:gap-16 items-center mb-8 xs:mb-0">
            <div
              className={`flex items-center justify-center mb-0 xs:mb-4 md:mb-0 -my-24 xs:-my-12 md:-my-10 lg:my-0 transition-opacity duration-500 ${
                isVisible ? `opacity-100` : `opacity-0`
              }`}
              style={{ transitionDelay: isVisible ? `700ms` : `0ms` }}
            >
              <div className="relative scale-[0.55] xs:scale-75 md:scale-100">
                <div
                  className={`transition-transform duration-700 ${
                    isVisible
                      ? `translate-x-0 translate-y-0`
                      : `-translate-x-12 translate-y-8`
                  }`}
                  style={{ transitionDelay: isVisible ? `900ms` : `0ms` }}
                >
                  <Tablet>
                    <PodcastPlayerScreen />
                  </Tablet>
                </div>
                <div
                  className={`absolute -right-24 -bottom-52 z-10 transition-transform duration-700 ${
                    isVisible
                      ? `translate-x-0 translate-y-0`
                      : `translate-x-12 translate-y-8`
                  }`}
                  style={{ transitionDelay: isVisible ? `1100ms` : `0ms` }}
                >
                  <Phone className="shadow-2xl scale-[0.47]" labelStatus="hidden">
                    <PincodeScreen isVisible={isVisible} />
                  </Phone>
                </div>
              </div>
            </div>

            <div
              className={`space-y-3 md:space-y-6 -mt-[7.5rem] xs:-mt-12 md:mt-0 transition-all duration-500 ${
                isVisible ? `translate-x-0 opacity-100` : `translate-x-16 opacity-0`
              }`}
              style={{ transitionDelay: isVisible ? `1300ms` : `0ms` }}
            >
              <FeatureCard
                icon={LockKeyholeIcon}
                title="Parents set PIN on first install"
                delay={isVisible ? 1400 : 0}
              />
              <FeatureCard
                icon={SearchXIcon}
                title="PIN required search or add shows"
                delay={isVisible ? 1600 : 0}
              />
              <FeatureCard
                icon={HeadphonesIcon}
                title="Approved shows always available"
                delay={isVisible ? 1800 : 0}
              />
            </div>
          </div>
        </div>

        <a
          href="https://apps.apple.com/us/app/gertrude-am/id6753187429?see-all=reviews&platform=iphone"
          target="_blank"
          rel="noopener noreferrer"
          className={`hidden md:flex flex-col items-center justify-center gap-1.5 my-8 md:mt-12 md:mb-16 text-white/50 text-sm hover:text-white/70 transition-all duration-500 antialiased relative z-10 ${
            isVisible ? `translate-y-0 opacity-100` : `translate-y-8 opacity-0`
          }`}
          style={{ transitionDelay: isVisible ? `2000ms` : `0ms` }}
        >
          <div
            className="flex items-center gap-1"
            role="img"
            aria-label="5 out of 5 stars"
          >
            {[...Array(5)].map((_, i) => (
              <StarIcon key={i} className="w-5 h-5 fill-current" aria-hidden="true" />
            ))}
          </div>
          <div className="flex items-center gap-1.5">
            <span>5-star rated on the App Store</span>
            <ExternalLinkIcon className="w-3 h-3" />
          </div>
        </a>

        <div
          className={`flex flex-col sm:flex-row items-center justify-center gap-6 sm:mt-8 md:mt-0 transition-all duration-500 ${
            isVisible ? `translate-y-0 opacity-100` : `translate-y-12 opacity-0`
          }`}
          style={{ transitionDelay: isVisible ? `2200ms` : `0ms` }}
        >
          <a
            href="https://apps.apple.com/us/app/gertrude-am/id6753187429"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-transform duration-200 hover:scale-105"
          >
            <img
              src="/download-on-app-store.svg"
              alt="Download on the App Store"
              width={168}
              height={56}
              className="h-10 xs:h-12 md:h-14"
            />
          </a>
          <div className="text-center sm:text-left">
            <p className="text-white/90 font-semibold text-sm xs:text-base md:text-lg">
              <span className="bg-gradient-to-r from-orange-200 to-orange-400 bg-clip-text text-transparent font-bold">
                $10/year
              </span>
              {` `}after 30-day trial
            </p>
            <p className="text-white/50 text-[0.65rem] xs:text-xs md:text-sm">
              Covers your entire Apple Family
            </p>
          </div>
        </div>
      </div>
    </section>
  );
};

const Tablet: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="w-[320px] h-[420px] rounded-[32px] bg-zinc-900 p-3 relative shadow-2xl">
    <div className="w-2.5 h-2.5 rounded-full bg-zinc-800 absolute left-1/2 -translate-x-1/2 top-3.5 z-10" />
    <div className="w-full h-full overflow-hidden rounded-[20px] bg-black">
      {children}
    </div>
  </div>
);

const PodcastPlayerScreen: React.FC = () => {
  const [elapsed, setElapsed] = useState(225);
  const [progress, setProgress] = useState(10);
  const totalDuration = 2212;

  useEffect(() => {
    const interval = setInterval(() => {
      setElapsed((prev) => (prev >= totalDuration ? 225 : prev + 1));
      setProgress((prev) => (prev >= 100 ? 10 : prev + 0.8));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  const formatTime = (seconds: number): string => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m}:${s.toString().padStart(2, `0`)}`;
  };

  const remaining = totalDuration - Math.floor((progress / 100) * totalDuration);

  return (
    <div className="w-full h-full bg-[rgb(237,233,254)] flex flex-col items-center justify-center p-4">
      <img
        src="/story-pirates.png"
        alt="Story Pirates podcast artwork"
        width={160}
        height={160}
        className="w-40 h-40 rounded-2xl shadow-xl mb-5"
      />
      <h3 className="text-slate-800 font-bold text-base mb-0.5">Story Pirates</h3>
      <p className="text-slate-500 text-xs mb-3">Alligator Droppings</p>
      <div className="w-full max-w-[240px] mb-3">
        <div className="h-1 bg-slate-300 rounded-full overflow-hidden">
          <div
            className="h-full bg-violet-500 rounded-full transition-all duration-1000 ease-linear"
            style={{ width: `${progress}%` }}
          />
        </div>
        <div className="flex justify-between text-slate-400 text-[10px] mt-0.5">
          <span>{formatTime(elapsed)}</span>
          <span>-{formatTime(remaining)}</span>
        </div>
      </div>
      <div className="flex items-center gap-5">
        <RotateCcwIcon className="w-5 h-5 text-slate-400" />
        <div className="w-14 h-14 rounded-full bg-violet-500 flex items-center justify-center">
          <PauseIcon className="w-6 h-6 text-white fill-white" />
        </div>
        <RotateCwIcon className="w-5 h-5 text-slate-400" />
      </div>
    </div>
  );
};

interface PincodeScreenProps {
  isVisible: boolean;
}

const PincodeScreen: React.FC<PincodeScreenProps> = ({ isVisible }) => {
  const [sheetVisible, setSheetVisible] = useState(false);
  const digits = [1, 2, 3, 4, 5, 6];
  const filledCount = 4;

  useEffect(() => {
    if (isVisible) {
      const timer = setTimeout(() => setSheetVisible(true), 2500);
      return () => clearTimeout(timer);
    }
  }, [isVisible]);

  return (
    <div className="w-full h-full bg-[rgb(237,233,254)] flex flex-col relative overflow-hidden">
      <div className="flex-1 flex flex-col items-center justify-center">
        <button className="bg-violet-500 text-white font-semibold text-xl px-8 py-4 rounded-full shadow-lg">
          + Add Show
        </button>
      </div>
      <div
        className="absolute bottom-0 left-0 right-0 h-[87%] bg-white rounded-t-3xl flex flex-col items-center justify-center p-6 shadow-2xl"
        style={{
          transform: sheetVisible ? `translateY(0)` : `translateY(100%)`,
          transition: `transform 0.5s cubic-bezier(0.32, 0.72, 0, 1)`,
        }}
      >
        <div className="w-12 h-1 bg-slate-300 rounded-full mb-3" />
        <h3 className="text-slate-800 font-semibold text-2xl mb-4">Enter PIN</h3>
        <div className="flex gap-3 mb-8">
          {digits.map((_, i) => (
            <div
              key={i}
              className={`w-4 h-4 rounded-full border-2 transition-all duration-300 ${
                i < filledCount ? `bg-violet-500 border-violet-500` : `border-slate-300`
              }`}
              style={{
                transitionDelay: sheetVisible ? `${500 + i * 150}ms` : `0ms`,
                opacity: sheetVisible ? 1 : 0,
                transform: sheetVisible ? `scale(1)` : `scale(0.5)`,
              }}
            />
          ))}
        </div>
        <div className="grid grid-cols-3 gap-3">
          {[1, 2, 3, 4, 5, 6, 7, 8, 9, null, 0, null].map((num, i) => (
            <div
              key={i}
              className={`w-16 h-16 rounded-full flex items-center justify-center text-2xl font-medium ${
                num === null ? `` : `bg-slate-100 text-slate-700 active:bg-slate-200`
              }`}
            >
              {num}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

interface FeatureCardProps {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  delay: number;
}

const FeatureCard: React.FC<FeatureCardProps> = ({ icon: Icon, title, delay }) => {
  const isVisible = useDelayedVisibility(delay);

  return (
    <div
      className={`bg-white/10 backdrop-blur-sm border border-white/20 rounded-xl xs:rounded-2xl p-3 xs:p-4 md:p-6 transition-all duration-500 hover:bg-white/15 hover:border-white/30 ${
        isVisible ? `opacity-100 translate-x-0` : `opacity-0 translate-x-8`
      }`}
    >
      <div className="flex items-center gap-2.5 xs:gap-3 md:gap-4">
        <div className="flex-shrink-0 w-9 h-9 xs:w-10 xs:h-10 md:w-12 md:h-12 rounded-lg xs:rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center">
          <Icon className="size-4 xs:size-5 md:size-6 text-white" />
        </div>
        <h3 className="text-sm xs:text-base md:text-lg md:leading-tight font-normal text-white leading-tight">
          {title}
        </h3>
      </div>
    </div>
  );
};

export default PodcastsBlock;
