'use client';

import { motion } from 'framer-motion';
import React from 'react';
import { useHeroEntranceReady } from '@/components/home/HomeHeroEntrance';
import { revealSpring, useMotionPreferences } from '@/lib/home-motion';

interface HomeHeroRiseProps {
  children: React.ReactNode;
  delay: number;
  distance: number;
  blur?: boolean;
  className?: string;
}

const HomeHeroRise: React.FC<HomeHeroRiseProps> = ({
  children,
  delay,
  distance,
  blur = false,
  className = ``,
}) => {
  const ready = useHeroEntranceReady();
  const { reducedMotion } = useMotionPreferences();
  const hidden = { opacity: 0, y: distance, filter: blur ? `blur(4px)` : `none` };
  const shown = {
    opacity: 1,
    y: 0,
    filter: blur ? `blur(0px)` : `none`,
    transitionEnd: { filter: `none` },
  };
  const fade = { duration: 0.3, ease: `easeOut`, delay: delay / 1000 } as const;

  return (
    <motion.span
      className={`home-hero-rise ${className}`}
      initial={hidden}
      animate={ready ? shown : hidden}
      transition={
        reducedMotion
          ? { duration: 0 }
          : { y: { ...revealSpring, delay: delay / 1000 }, opacity: fade, filter: fade }
      }
    >
      {children}
    </motion.span>
  );
};

export default HomeHeroRise;
