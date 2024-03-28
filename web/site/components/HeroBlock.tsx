'use client';

import { ChevronDownIcon } from 'lucide-react';
import React from 'react';
import cx from 'classnames';
import { useScrollY } from '../lib/hooks';

const HeroBlock: React.FC = () => {
  const scrollY = useScrollY();

  return (
    <section className="bg-gradient-to-b from-violet-500 to-fuchsia-500 p-20 h-screen flex flex-col justify-center items-center relative snap-center -mt-20">
      <h1
        className="text-5xl xs:text-6xl sm:text-7xl text-center text-white font-semibold fixed px-12 xs:px-16 sm:px-20 !leading-[1.1em] font-axiforma"
        style={{
          transform: `scale(${1 + scrollY / 500})`,
          filter: `blur(${scrollY / 30}px)`,
          opacity: 1 - scrollY / 500,
          display: scrollY > 500 ? `none` : `block`,
        }}
      >
        Finally, real internet safety is possible.
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
