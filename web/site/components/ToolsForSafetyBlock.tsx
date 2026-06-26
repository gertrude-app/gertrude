'use client';

import cx from 'classnames';
import { LaptopIcon, MusicIcon, PodcastIcon, TabletSmartphoneIcon } from 'lucide-react';
import React, { useEffect, useState } from 'react';
import { useScrollY } from '../lib/hooks';

const initialPhrases = [
  `internet safety.`,
  `protecting kids.`,
  `peace of mind.`,
  `blocking porn.`,
  `normal parents.`,
  `clean content.`,
  `innocence.`,
  `Apple families.`,
];

const ToolsForSafetyBlock: React.FC = () => {
  const [phrases, setPhrases] = useState(initialPhrases);
  const [phraseIndex, setPhraseIndex] = useState(0);
  const [displayedText, setDisplayedText] = useState(``);
  const [isDeleting, setIsDeleting] = useState(false);
  const scrollY = useScrollY();

  useEffect(() => {
    const rest = initialPhrases.slice(1).sort(() => Math.random() - 0.5);
    setPhrases([initialPhrases[0] ?? `internet safety.`, ...rest]);
  }, []);

  useEffect(() => {
    const currentPhrase = phrases[phraseIndex] ?? ``;
    const typingSpeed = isDeleting ? 15 : 60;
    const pauseAfterTyping = 2000;

    if (!isDeleting && displayedText === currentPhrase) {
      const timeout = setTimeout(() => setIsDeleting(true), pauseAfterTyping);
      return () => clearTimeout(timeout);
    }

    if (isDeleting && displayedText === ``) {
      setIsDeleting(false);
      setPhraseIndex((current) => (current + 1) % phrases.length);
      return;
    }

    const timeout = setTimeout(() => {
      setDisplayedText(
        isDeleting
          ? currentPhrase.slice(0, displayedText.length - 1)
          : currentPhrase.slice(0, displayedText.length + 1),
      );
    }, typingSpeed);

    return () => clearTimeout(timeout);
  }, [displayedText, isDeleting, phraseIndex, phrases]);

  const scrollProgress = Math.min(scrollY / 600, 1);

  return (
    <section className="min-h-screen bg-gradient-to-br from-white via-white via-55% to-fuchsia-200 px-4 xs:px-6 sm:px-8 md:px-20 pt-4 xs:pt-16 sm:pt-20 md:pt-24 pb-12 xs:pb-16 sm:pb-20 md:pb-24 flex flex-col items-center justify-center relative overflow-hidden">
      <div
        className="absolute inset-0 bg-gradient-to-b from-white to-fuchsia-600 pointer-events-none"
        style={{ opacity: scrollProgress * 0.7 }}
      />
      <svg width="0" height="0" style={{ position: `absolute` }}>
        <defs>
          <linearGradient id="icon-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style={{ stopColor: `#a855f7`, stopOpacity: 1 }} />
            <stop offset="100%" style={{ stopColor: `#d946ef`, stopOpacity: 1 }} />
          </linearGradient>
        </defs>
      </svg>
      <div
        className="flex flex-col items-center w-full"
        style={{
          transform: `scale(${1 + scrollProgress * 0.15})`,
          filter: `blur(${scrollProgress * 8}px)`,
          opacity: 1 - scrollProgress * 0.8,
        }}
      >
        <div className="text-center w-full pt-4 xs:pt-0">
          <h1 className="text-4xl xs:text-5xl sm:text-6xl md:text-7xl font-bold text-slate-800 !leading-[1.15em]">
            <span className="block lg:inline">Tools for{` `}</span>
            <span className="sr-only">{initialPhrases.join(`, `)}</span>
            <span
              aria-hidden
              className="inline-block bg-gradient-to-r from-purple-600 to-fuchsia-500 bg-clip-text text-transparent"
            >
              {displayedText}
              <span className="animate-blink text-fuchsia-400">|</span>
            </span>
          </h1>
        </div>

        <div className="mt-12 xs:mt-16 md:mt-20 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 xs:gap-8 lg:gap-6 xl:gap-8 w-full max-w-6xl justify-items-center sm:justify-items-stretch">
          <ProductCard
            icon={TabletSmartphoneIcon}
            label="iPhone & iPad"
            description="Plug holes in Screen Time, including #images GIF search"
            delay={500}
            href="#ios"
          />
          <ProductCard
            icon={LaptopIcon}
            label="Mac"
            description="Comprehensive web filtering and screenshot monitoring"
            delay={700}
            href="#mac"
          />
          <ProductCard
            icon={PodcastIcon}
            label="Podcasts"
            description="Parent-managed podcasts protected by PIN code"
            delay={900}
            href="#podcasts"
          />
          <ProductCard
            icon={MusicIcon}
            label="Music"
            description="Only approved music, nothing else"
            delay={1100}
            comingSoon
          />
        </div>

        <p
          className="mt-24 xs:mt-28 max-w-xl px-8 xs:px-10 sm:px-0 text-center text-slate-500 text-xs xs:text-sm md:text-base leading-snug antialiased animate-fadeIn opacity-0"
          style={{ animationDelay: `1300ms`, animationFillMode: `forwards` }}
        >
          iPhone, iPad, and Mac all connect to{` `}
          <span className="font-semibold text-fuchsia-600">one Gertrude account</span>
          {` `}for your family.
        </p>
      </div>
    </section>
  );
};

interface ProductCardProps {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  description: string;
  delay: number;
  href?: string;
  comingSoon?: boolean;
}

const ProductCard: React.FC<ProductCardProps> = ({
  icon: Icon,
  label,
  description,
  delay,
  href,
  comingSoon = false,
}) => {
  const isDisabled = !href;
  const content = (
    <>
      <div
        className={cx(
          `relative shrink-0 bg-white/80 backdrop-blur-sm rounded-2xl xs:rounded-3xl p-4 xs:p-6 md:p-8 sm:mb-4 md:mb-6 border border-fuchsia-200 shadow-lg shadow-fuchsia-100`,
          !isDisabled &&
            `transition-all duration-300 group-hover:scale-105 group-hover:border-fuchsia-400 group-hover:shadow-xl group-hover:shadow-fuchsia-200`,
          isDisabled && `border-violet-200 shadow-violet-100`,
        )}
      >
        {comingSoon && (
          <div className="absolute bottom-0 left-1/2 z-10 -translate-x-1/2 translate-y-1/2 whitespace-nowrap rounded-full bg-gradient-to-r from-violet-600 to-fuchsia-500 px-2.5 py-1 text-[9px] font-bold uppercase tracking-wide text-white shadow-lg shadow-fuchsia-300/40 xs:px-3 xs:text-[10px]">
            Coming soon!
          </div>
        )}
        <Icon
          className={cx(
            `size-10 xs:size-12 sm:size-10 md:size-16 [&_*]:stroke-[url(#icon-gradient)] [&_circle]:fill-[url(#icon-gradient)]`,
            !isDisabled && `transition-transform duration-300 group-hover:scale-110`,
            isDisabled && `opacity-60 grayscale`,
          )}
        />
      </div>
      <div>
        <h3
          className={cx(
            `text-lg xs:text-xl md:text-3xl font-semibold text-slate-800 mb-0.5 xs:mb-1 md:mb-2 transition-colors duration-300`,
            !isDisabled && `group-hover:text-fuchsia-600`,
            isDisabled && `text-slate-500`,
          )}
        >
          {label}
        </h3>
        <p
          className={cx(
            `text-slate-500 text-xs xs:text-sm md:text-base leading-snug max-w-[200px] sm:max-w-none antialiased`,
            isDisabled && `text-slate-400`,
          )}
        >
          {description}
        </p>
      </div>
    </>
  );

  if (isDisabled) {
    return (
      <div
        aria-disabled="true"
        className="flex flex-row sm:flex-col items-center sm:text-center animate-fadeIn opacity-0 gap-4 sm:gap-0 cursor-default"
        style={{ animationDelay: `${delay}ms`, animationFillMode: `forwards` }}
      >
        {content}
      </div>
    );
  }

  return (
    <a
      href={href}
      onClick={(e) => {
        const target = document.querySelector(href);
        if (target) {
          e.preventDefault();
          target.scrollIntoView({ behavior: `smooth` });
        }
      }}
      className="flex flex-row sm:flex-col items-center sm:text-center group animate-fadeIn opacity-0 gap-4 sm:gap-0"
      style={{ animationDelay: `${delay}ms`, animationFillMode: `forwards` }}
    >
      {content}
    </a>
  );
};

export default ToolsForSafetyBlock;
