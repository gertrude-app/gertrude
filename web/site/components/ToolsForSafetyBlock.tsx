'use client';

import cx from 'classnames';
import React, { useEffect, useState } from 'react';
import { useScrollY } from '../lib/hooks';

const GROUP_REVEAL_DELAY = 850;

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
    <section className="min-h-screen bg-gradient-to-br from-white via-white via-55% to-fuchsia-200 px-4 xs:px-6 sm:px-8 md:px-20 pt-24 xs:pt-28 sm:pt-24 md:pt-28 pb-12 xs:pb-16 sm:pb-20 md:pb-24 flex flex-col items-center justify-start sm:justify-center relative overflow-x-hidden md:overflow-hidden">
      <div
        className="absolute inset-0 bg-gradient-to-b from-white to-fuchsia-600 pointer-events-none"
        style={{ opacity: scrollProgress * 0.7 }}
      />
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

        <div className="mt-12 grid w-full max-w-6xl grid-cols-1 gap-10 xs:mt-14 md:mt-16 lg:grid-cols-2 lg:gap-0">
          <ProductGroup
            title="Powerful protection & accountability"
            revealDelay={GROUP_REVEAL_DELAY}
            className="lg:pr-10 xl:pr-12"
          >
            <ProductCard
              iconSrc="/app-icons/gertrude.webp"
              label="iPhone & iPad"
              description="Plug holes in Screen Time, including #images GIF search"
              delay={150}
              href="#ios"
            />
            <ProductCard
              iconSrc="/app-icons/gertrude.webp"
              label="Mac"
              description="Comprehensive web filtering and screenshot monitoring"
              delay={250}
              href="#mac"
            />
          </ProductGroup>
          <ProductGroup
            title="Truly safe, parent-curated media"
            revealDelay={GROUP_REVEAL_DELAY}
            divider
            className="lg:pl-10 xl:pl-12"
          >
            <ProductCard
              iconSrc="/app-icons/music.webp"
              label="Music"
              description="Only approved music, nothing else"
              delay={350}
              href="#music"
            />
            <ProductCard
              iconSrc="/app-icons/podcasts.webp"
              label="Podcasts"
              description="Parent-managed podcasts protected by PIN code"
              delay={450}
              href="#podcasts"
            />
          </ProductGroup>
        </div>

        <p
          className="mt-16 max-w-xl px-8 text-center text-xs leading-snug text-slate-500 opacity-0 antialiased animate-fadeIn xs:mt-20 xs:px-10 xs:text-sm sm:px-0 md:text-base"
          style={{ animationDelay: `950ms`, animationFillMode: `forwards` }}
        >
          iPhone, iPad, and Mac all connect to{` `}
          <span className="font-semibold text-fuchsia-600">one Gertrude account</span>
          {` `}for your family.
        </p>
      </div>
    </section>
  );
};

const ProductGroup: React.FC<{
  title: string;
  revealDelay: number;
  divider?: boolean;
  className?: string;
  children: React.ReactNode;
}> = ({ title, revealDelay, divider = false, className, children }) => (
  <section className={cx(`relative`, className)}>
    {divider && (
      <span
        className="absolute -left-px top-0 hidden h-full w-px bg-fuchsia-200/70 opacity-0 animate-fade-in lg:block"
        style={{ animationDelay: `${revealDelay}ms` }}
      />
    )}
    <h2
      className="mb-6 text-center text-sm font-medium text-slate-500 opacity-0 animate-fade-in xs:text-base md:text-lg"
      style={{ animationDelay: `${revealDelay}ms` }}
    >
      {title}
    </h2>
    <div className="grid grid-cols-1 gap-5 xs:gap-6 sm:grid-cols-2 sm:gap-8 lg:gap-6 xl:gap-8">
      {children}
    </div>
  </section>
);

interface ProductCardProps {
  iconSrc: string;
  label: string;
  description: string;
  delay: number;
  href?: string;
}

const ProductCard: React.FC<ProductCardProps> = ({
  iconSrc,
  label,
  description,
  delay,
  href,
}) => {
  const isDisabled = !href;
  const content = (
    <>
      <img
        src={iconSrc}
        alt=""
        width={400}
        height={400}
        className={cx(
          `size-[4.5rem] shrink-0 object-contain drop-shadow-[0_12px_24px_rgba(126,34,206,0.2)] xs:size-24 sm:mb-4 sm:size-[5.5rem] md:mb-6 md:size-32`,
          !isDisabled && `transition-transform duration-300 group-hover:scale-105`,
          isDisabled && `opacity-60 grayscale`,
        )}
      />
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
        const target = href.startsWith(`#`) ? document.querySelector(href) : null;
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
