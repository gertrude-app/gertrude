'use client';

import cx from 'classnames';
import { ChevronDownIcon } from 'lucide-react';
import React, { useEffect, useState } from 'react';
import { useScrollY } from '../lib/hooks';
import AnimatedUnderline from './AnimatedUnderline';
import Computer from './super-scroller-illustration/Computer';

const HeroBlock: React.FC = () => {
  const scrollY = useScrollY();
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    setIsVisible(true);
  }, []);

  return (
    <section className="bg-gradient-to-b from-violet-500 to-fuchsia-500 p-20 h-screen flex flex-col justify-center items-center relative snap-center -mt-20 overflow-hidden">
      <div
        className="absolute inset-0 flex items-center justify-center pointer-events-none"
        style={{
          opacity: Math.max(0, 0.08 - scrollY / 4000),
        }}
      >
        <Computer
          className="scale-50 xs:scale-75 sm:scale-90 lg:scale-100 -translate-y-16"
          labelStatus="hidden"
        >
          <div className="w-full h-full bg-slate-700" />
        </Computer>
      </div>
      <h1
        className="text-5xl xs:text-6xl sm:text-7xl text-center text-white font-bold fixed px-12 xs:px-16 sm:px-20 tracking-[0.02em] !leading-[1.1em] w-full"
        style={{
          transform: `scale(${1 + scrollY / 500})`,
          filter: `blur(${scrollY / 30}px)`,
          opacity: 1 - scrollY / 500,
          display: scrollY > 500 ? `none` : `block`,
        }}
      >
        Total internet safety for{` `}
        <span className="relative inline-block">
          Mac
          <AnimatedUnderline
            isVisible={isVisible}
            delay={800}
            gradientId="hero-mac-underline"
            fromColor="#a78bfa"
            toColor="#e879f9"
            height={8}
            strokeWidth={4}
            className="absolute bottom-0 left-0 w-full translate-y-1 xs:translate-y-2"
          />
        </span>
        {` `}computers.
      </h1>
      <div
        className={cx(
          `absolute bottom-6 flex flex-col items-center transition-[opacity,transform] duration-500`,
          scrollY !== 0 && `opacity-0 translate-y-4`,
        )}
      >
        <span className="font-medium text-white/30 uppercase tracking-[3px] text-sm sm:text-base">
          Scroll
        </span>
        <ChevronDownIcon className="h-5 sm:h-6 w-5 sm:w-6 text-white/30 animate-bounce mt-1 sm:mt-2" />
      </div>
    </section>
  );
};

export default HeroBlock;
