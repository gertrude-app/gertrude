'use client';

import { type MotionStyle, motion, useSpring } from 'framer-motion';
import React from 'react';
import { useHeroEntranceReady } from '@/components/home/HomeHeroEntrance';
import { cssTimeToMilliseconds, useMotionPreferences } from '@/lib/home-motion';

interface HomeHeroPhraseProps {
  children: React.ReactNode;
  variant: `safety` | `accountability` | `media` | `apple`;
}

const HomeHeroPhrase: React.FC<HomeHeroPhraseProps> = ({ children, variant }) => {
  const ref = React.useRef<HTMLSpanElement>(null);
  const ready = useHeroEntranceReady();
  const { reducedMotion } = useMotionPreferences();
  const progress = useSpring(0, { stiffness: 460, damping: 22, mass: 0.65 });

  React.useLayoutEffect(() => {
    const element = ref.current;
    if (!element || !ready) return;
    if (reducedMotion || window.matchMedia(`(prefers-reduced-motion: reduce)`).matches) {
      progress.jump(1);
      return;
    }
    const style = getComputedStyle(element);
    const delay = cssTimeToMilliseconds(style.getPropertyValue(`--hero-phrase-delay`));
    const scale = parseFloat(style.getPropertyValue(`--home-hero-timing-scale`));
    const timer = setTimeout(() => progress.set(1), delay * scale);
    return () => clearTimeout(timer);
  }, [progress, ready, reducedMotion]);

  return (
    <motion.span
      ref={ref}
      className={`hero-phrase hero-phrase-${variant} rounded-[0.5em] inline-flex items-center`}
      style={{ [`--hero-phrase-progress`]: progress } as MotionStyle}
    >
      {children}
    </motion.span>
  );
};

export default HomeHeroPhrase;
