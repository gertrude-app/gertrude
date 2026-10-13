'use client';

import React from 'react';
import HomeMusicSection from '@/components/home/HomeMusicSection';
import HomePodcastsSection from '@/components/home/HomePodcastsSection';
import HomeSectionRails from '@/components/home/HomeSectionRails';

const HomeCuratedMediaSection: React.FC = () => {
  const sectionRef = React.useRef<HTMLElement>(null);
  const [isDark, setIsDark] = React.useState(false);

  React.useEffect(() => {
    const section = sectionRef.current;
    if (!section) return;

    const updateTheme = (): void => {
      const bounds = section.getBoundingClientRect();
      setIsDark(bounds.top <= 0 && bounds.bottom >= window.innerHeight);
    };

    updateTheme();
    window.addEventListener(`scroll`, updateTheme, { passive: true });
    window.addEventListener(`resize`, updateTheme);
    return () => {
      window.removeEventListener(`scroll`, updateTheme);
      window.removeEventListener(`resize`, updateTheme);
    };
  }, []);

  return (
    <section
      ref={sectionRef}
      data-home-header-theme="dark"
      aria-labelledby="curated-media-heading"
      className={`border-t transition-colors duration-700 ${
        isDark ? `border-white/[0.06] bg-stone-950` : `border-stone-200/80 bg-white`
      }`}
    >
      <HomeSectionRails
        className={`overflow-hidden px-8 pt-40 pb-40 transition-colors duration-700 lg:px-10 lg:pt-56 lg:pb-56 ${
          isDark ? `border-white/[0.08] bg-stone-950` : `border-stone-200/80 bg-stone-50`
        }`}
      >
        <div className="pl-4 sm:pl-6">
          <h2
            id="curated-media-heading"
            className={`max-w-6xl text-pretty text-5xl font-semibold leading-[0.95] tracking-[-0.06em] transition-colors duration-700 xs:text-6xl sm:text-7xl lg:text-8xl xl:text-9xl ${
              isDark ? `text-stone-50` : `text-stone-950`
            }`}
          >
            <span>Let’s talk about</span>
            <br />
            <AnimatedMedia isDark={isDark} />
          </h2>
          <div className="mt-24 max-w-5xl lg:mt-36">
            <h3
              className={`max-w-4xl text-pretty text-3xl font-semibold leading-[1.05] tracking-[-0.04em] transition-colors duration-700 sm:text-4xl lg:text-5xl ${
                isDark ? `text-stone-50` : `text-stone-950`
              }`}
            >
              An endless catalog is impossible to monitor.
              <span
                className={`mt-2 block transition-colors duration-700 ${
                  isDark ? `text-violet-400` : `text-violet-600`
                }`}
              >
                Control what’s available instead.
              </span>
            </h3>
            <p
              className={`mt-8 max-w-3xl text-xl leading-8 transition-colors duration-700 ${
                isDark ? `text-stone-300` : `text-stone-600`
              }`}
            >
              Music and podcast apps put millions of songs and shows just one search
              away—including sexual, violent, and deeply disturbing content. Explicit
              labels catch only a fraction of it, and no parent or accountability partner
              can inspect every result or recommendation.
            </p>
            <p
              className={`mt-5 max-w-3xl text-xl leading-8 transition-colors duration-700 ${
                isDark ? `text-stone-300` : `text-stone-600`
              }`}
            >
              Gertrude replaces open-ended exploration with a library you control. Decide
              exactly which music can play, and require your PIN before new podcasts can
              be added.
            </p>
          </div>
        </div>
      </HomeSectionRails>
      <HomeMusicSection isDark={isDark} />
      <HomePodcastsSection isDark={isDark} />
    </section>
  );
};

export default HomeCuratedMediaSection;

interface AnimatedMediaProps {
  isDark: boolean;
}

const AnimatedMedia: React.FC<AnimatedMediaProps> = ({ isDark }) => {
  const wordRef = React.useRef<HTMLSpanElement>(null);
  const [hasEntered, setHasEntered] = React.useState(false);

  React.useEffect(() => {
    const word = wordRef.current;
    if (!word) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting) return;
        setHasEntered(true);
        observer.disconnect();
      },
      { threshold: 0.6 },
    );

    observer.observe(word);
    return () => observer.disconnect();
  }, []);

  return (
    <span ref={wordRef} className="relative inline-block whitespace-nowrap">
      <span
        className={`relative transition-colors duration-700 ${
          isDark ? `text-white` : `text-black`
        }`}
      >
        <AnimatedMediaGlyphs hasEntered={hasEntered} />
      </span>
      <span
        aria-hidden
        className={`pointer-events-none absolute inset-y-0 left-0 -right-[0.08em] bg-[url('/home/grainy-gradient.webp')] bg-[length:100%_100%] bg-no-repeat bg-clip-text text-transparent transition-opacity duration-700 ${
          isDark ? `opacity-40` : `opacity-0`
        }`}
      >
        <AnimatedMediaGlyphs hasEntered={hasEntered} />
      </span>
      <span
        aria-hidden
        className={`pointer-events-none absolute inset-y-0 left-0 -right-[0.08em] bg-[url('/home/dot-noise-pattern.svg')] bg-[length:1440px_1440px] bg-repeat bg-clip-text text-transparent transition-opacity duration-700 ${
          isDark ? `opacity-100` : `opacity-0`
        }`}
        style={{
          WebkitMaskImage: `linear-gradient(to bottom, transparent, black)`,
          maskImage: `linear-gradient(to bottom, transparent, black)`,
        }}
      >
        <AnimatedMediaGlyphs hasEntered={hasEntered} />
      </span>
    </span>
  );
};

const mediaSegments = [...`medi`, `a.`];

const AnimatedMediaGlyphs: React.FC<{ hasEntered: boolean }> = ({ hasEntered }) => {
  const initialDelay = 300;
  const stagger = 80;
  return mediaSegments.map((segment, index) => (
    <span
      key={`${segment}-${index}`}
      className={`home-mac-letter-ripple ${
        hasEntered ? `home-mac-letter-ripple-visible` : ``
      }`}
      style={{
        animationDelay: hasEntered ? `${initialDelay + index * stagger}ms` : `0ms`,
      }}
    >
      {segment}
    </span>
  ));
};
