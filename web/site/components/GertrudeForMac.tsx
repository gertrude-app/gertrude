'use client';

import {
  Clock4Icon,
  MonitorDot,
  RocketIcon,
  ShieldCheckIcon,
  SmartphoneIcon,
} from 'lucide-react';
import React, { useEffect, useRef, useState } from 'react';
import AnimatedUnderline from './AnimatedUnderline';
import Computer from './super-scroller-illustration/Computer';
import {
  useDelayedVisibility,
  useIntersectionVisibility,
  useScrollProgress,
} from '@/lib/hooks';

const GertrudeForMac: React.FC = () => {
  const [isMdOrLarger, setIsMdOrLarger] = useState(true);
  const wrapperRef = useRef<HTMLDivElement>(null);
  const stickyRef = useRef<HTMLDivElement>(null);
  const isVisible = useIntersectionVisibility(stickyRef, 0.5);
  const scrollProgress = useScrollProgress(wrapperRef);
  const exitProgress = isMdOrLarger ? scrollProgress : 0;

  useEffect(() => {
    const checkWidth = (): void => setIsMdOrLarger(window.innerWidth >= 768);
    checkWidth();
    window.addEventListener(`resize`, checkWidth);
    return () => window.removeEventListener(`resize`, checkWidth);
  }, []);

  return (
    <div
      id="mac"
      ref={wrapperRef}
      className={isMdOrLarger ? `h-[280vh] relative` : `relative`}
    >
      <section
        ref={stickyRef}
        className={`${isMdOrLarger ? `sticky top-0` : ``} min-h-screen overflow-hidden`}
      >
        <div
          className="absolute inset-0 bg-gradient-to-b from-violet-950 to-black pointer-events-none z-10"
          style={{ opacity: Math.max(0, (exitProgress - 0.45) / 0.55) * 0.9 }}
        />
        <div
          className="min-h-screen bg-slate-900 px-6 sm:px-12 md:px-20 pt-12 xs:pt-16 sm:pt-12 md:pt-[10vh] pb-16 relative overflow-hidden"
          style={{
            filter: `blur(${Math.max(0, (exitProgress - 0.45) / 0.55) * 8}px)`,
          }}
        >
          <div className="[background:radial-gradient(#a78bfa44,transparent_70%)] w-176 h-176 absolute -right-80 -top-80" />
          <div className="[background:radial-gradient(#e879f944,transparent_70%)] w-176 h-176 absolute -left-80 top-20" />
          <div className="[background:radial-gradient(#a78bfa30,transparent_70%)] w-176 h-176 absolute -right-40 -bottom-96" />
          <div
            className={`absolute inset-0 flex items-end justify-center pb-16 xs:pb-48 sm:pb-[20rem] pointer-events-none transition-opacity duration-500 ${
              !isVisible
                ? `opacity-0`
                : exitProgress === 0
                  ? `opacity-30 sm:opacity-20 delay-[1500ms]`
                  : `opacity-30 sm:opacity-20`
            }`}
            style={
              exitProgress > 0.35
                ? {
                    opacity:
                      (window.innerWidth < 640 ? 0.3 : 0.2) *
                      (1 - (exitProgress - 0.35) / 0.65),
                  }
                : undefined
            }
          >
            <Computer
              className="scale-[0.6] xs:scale-90 lg:scale-110"
              labelStatus="hidden"
            >
              <div className="w-full h-full bg-slate-950" />
            </Computer>
          </div>

          <div className="max-w-6xl mx-auto relative">
            <div className="text-center mb-10 xs:mb-12 sm:mb-20">
              <div
                className={`inline-block px-3 xs:px-6 py-1.5 xs:py-3 bg-white/10 backdrop-blur-sm rounded-full mb-4 xs:mb-6 border border-white/20 ${
                  isVisible && exitProgress === 0
                    ? `translate-x-0 opacity-100`
                    : !isVisible
                      ? `translate-x-[500px] opacity-0`
                      : ``
                }`}
                style={{
                  transition: `transform 0.25s cubic-bezier(0.2, 1.4, 0.5, 1), opacity 0.25s ease-out`,
                  transitionDelay: isVisible && exitProgress === 0 ? `200ms` : `0ms`,
                  ...(exitProgress > 0.35 && {
                    transform: `translateX(${((exitProgress - 0.35) / 0.65) * 500}px)`,
                    opacity: 1 - (exitProgress - 0.35) / 0.65,
                  }),
                }}
              >
                <span className="text-xs xs:text-sm font-bold bg-gradient-to-r from-violet-300 to-fuchsia-300 bg-clip-text text-transparent tracking-wider">
                  FLAGSHIP PRODUCT
                </span>
              </div>
              <h2
                className={`text-[2.5rem] xs:text-5xl sm:text-6xl md:text-7xl lg:text-8xl font-bold mb-6 transition-all duration-500 ${
                  isVisible && exitProgress === 0
                    ? `translate-x-0 opacity-100`
                    : !isVisible
                      ? `-translate-x-24 opacity-0`
                      : ``
                }`}
                style={{
                  transitionDelay: isVisible && exitProgress === 0 ? `600ms` : `0ms`,
                  ...(exitProgress > 0.35 && {
                    transform: `translateX(${(-(exitProgress - 0.35) / 0.65) * 100}px)`,
                    opacity: 1 - (exitProgress - 0.35) / 0.65,
                  }),
                }}
              >
                <span className="bg-gradient-to-r from-violet-400 to-fuchsia-400 bg-clip-text text-transparent">
                  Gertrude for{` `}
                </span>
                <span className="relative inline-block bg-gradient-to-r from-white to-violet-300 bg-clip-text text-transparent">
                  Mac
                  <AnimatedUnderline
                    isVisible={isVisible}
                    delay={1000}
                    gradientId="mac-underline-gradient"
                    fromColor="#a78bfa"
                    toColor="#e879f9"
                    height={8}
                    strokeWidth={4}
                    className="absolute bottom-0 left-0 w-full -translate-y-1 xs:translate-y-2"
                  />
                </span>
              </h2>
              <p
                className={`text-sm xs:text-base sm:text-xl md:text-2xl text-violet-300 max-w-3xl mx-auto leading-snug xs:leading-relaxed transition-all duration-500 ${
                  isVisible && exitProgress === 0
                    ? `translate-x-0 opacity-100`
                    : !isVisible
                      ? `translate-x-24 opacity-0`
                      : ``
                }`}
                style={{
                  transitionDelay: isVisible && exitProgress === 0 ? `1000ms` : `0ms`,
                  ...(exitProgress > 0.35 && {
                    transform: `translateX(${((exitProgress - 0.35) / 0.65) * 100}px)`,
                    opacity: 1 - (exitProgress - 0.35) / 0.65,
                  }),
                }}
              >
                Comprehensive web filtering and activity monitoring. The most powerful
                parental controls ever built for macOS.
              </p>
            </div>

            <div
              className={`grid sm:grid-cols-2 lg:grid-cols-4 gap-3 xs:gap-4 sm:gap-6 transition-all duration-500 ${
                isVisible && exitProgress === 0
                  ? `translate-x-0 opacity-100`
                  : !isVisible
                    ? `-translate-x-24 opacity-0`
                    : ``
              }`}
              style={{
                transitionDelay: isVisible && exitProgress === 0 ? `1400ms` : `0ms`,
                ...(exitProgress > 0.35 && {
                  transform: `translateX(${(-(exitProgress - 0.35) / 0.65) * 100}px)`,
                  opacity: 1 - (exitProgress - 0.35) / 0.65,
                }),
              }}
            >
              <FeatureCard
                icon={ShieldCheckIcon}
                title="Filter"
                description="Everything is blocked. Unlock only what you approve."
                delay={0}
              />
              <FeatureCard
                icon={MonitorDot}
                title="Record"
                description="Capture screenshots and typing for full transparency."
                delay={isVisible ? 150 : 0}
              />
              <FeatureCard
                icon={Clock4Icon}
                title="Schedule"
                description="Allow apps and websites on custom timeframes."
                delay={isVisible ? 300 : 0}
              />
              <FeatureCard
                icon={SmartphoneIcon}
                title="Relax"
                description="Control and monitor wherever you are, from any device."
                delay={isVisible ? 450 : 0}
              />
            </div>

            <div
              className={`flex flex-col items-center mt-16 gap-6 transition-opacity duration-500 ${
                isVisible && exitProgress === 0
                  ? `opacity-100`
                  : !isVisible
                    ? `opacity-0`
                    : ``
              }`}
              style={{
                transitionDelay: isVisible && exitProgress === 0 ? `1800ms` : `0ms`,
                ...(exitProgress > 0.35 && {
                  opacity: 1 - (exitProgress - 0.35) / 0.65,
                }),
              }}
            >
              <a
                href="/mac"
                className="group relative px-10 py-5 bg-gradient-to-r from-violet-500 to-fuchsia-500 rounded-2xl text-white text-xl font-bold transition-all duration-300 hover:scale-105 hover:shadow-[0_0_40px_rgba(168,85,247,0.4)] active:scale-100"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-violet-400 to-fuchsia-400 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                <span className="relative flex items-center gap-3">
                  <RocketIcon size={28} />
                  Get started
                </span>
              </a>
              <p className="text-violet-300/60 text-xs xs:text-sm sm:text-base">
                $10/month for the whole family, 21 day free trial
              </p>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

interface FeatureCardProps {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
  delay: number;
}

const FeatureCard: React.FC<FeatureCardProps> = ({
  icon: Icon,
  title,
  description,
  delay,
}) => {
  const isVisible = useDelayedVisibility(delay);

  return (
    <div
      className={`flex flex-row lg:flex-col items-start gap-4 lg:gap-0 bg-slate-800/50 backdrop-blur-sm border border-violet-500/20 rounded-2xl p-4 xs:p-5 lg:p-6 transition-all duration-500 hover:border-violet-500/40 hover:bg-slate-800/70 ${
        isVisible ? `opacity-100 translate-y-0` : `opacity-0 translate-y-8`
      }`}
    >
      <div className="size-10 xs:size-11 sm:size-12 shrink-0 rounded-lg bg-gradient-to-br from-violet-500 to-fuchsia-500 flex items-center justify-center lg:mb-4">
        <Icon className="size-5 xs:size-[1.375rem] sm:size-6 text-white" />
      </div>
      <div className="-mt-0.5 lg:mt-0">
        <h3 className="text-base xs:text-[1.0625rem] sm:text-lg font-semibold text-white mb-0.5 lg:mb-2">
          {title}
        </h3>
        <p className="text-violet-300/80 text-xs xs:text-[0.8125rem] sm:text-sm leading-snug">
          {description}
        </p>
      </div>
    </div>
  );
};

export default GertrudeForMac;
