'use client';

import React from 'react';
import { useIntersectionVisibility } from '@/lib/hooks';

interface LetterRippleGlyphsProps {
  segments: readonly string[];
  active: boolean;
}

export const LetterRippleGlyphs: React.FC<LetterRippleGlyphsProps> = ({
  segments,
  active,
}) =>
  segments.map((segment, index) => (
    <span
      key={`${segment}-${index}`}
      className={`home-mac-letter-ripple ${active ? `home-mac-letter-ripple-visible` : ``}`}
      style={{ animationDelay: active ? `${300 + index * 80}ms` : `0ms` }}
    >
      {segment}
    </span>
  ));

const HomeLetterRipple: React.FC<{ text: string }> = ({ text }) => {
  const ref = React.useRef<HTMLSpanElement>(null);
  const active = useIntersectionVisibility(ref, 0.6);
  return (
    <span ref={ref}>
      <LetterRippleGlyphs segments={[...text]} active={active} />
    </span>
  );
};

export default HomeLetterRipple;
