'use client';

import {
  type MotionValue,
  motion,
  useMotionTemplate,
  useMotionValue,
  useMotionValueEvent,
  useSpring,
  useTransform,
} from 'framer-motion';
import { ShieldCheckIcon } from 'lucide-react';
import { Rubik } from 'next/font/google';
import React from 'react';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { useIntersectionVisibility } from '@/lib/hooks';

// eslint-disable-next-line @stylistic/quotes
const rubik = Rubik({ subsets: ['latin'], display: 'swap' });

const entryPoints = [
  `A browser.`,
  `An app.`,
  `A search.`,
  `A message.`,
  `An image picker.`,
  `A private window.`,
  `A media catalog.`,
  `A new website.`,
  `A social feed.`,
  `A shared link.`,
  `A video.`,
  `A group chat.`,
  `An AI chatbot.`,
  `A game.`,
  `A recommendation.`,
  `A file download.`,
];

const HomeProblemSection: React.FC = () => (
  <section
    id="internet-safety"
    className="scroll-mt-24 border-t border-stone-200/80 bg-white"
  >
    <HomeSectionRails className="bg-stone-50 px-8 py-20 sm:py-28 lg:px-10 lg:py-40">
      <div className="sm:pl-6">
        <h2 className="max-w-6xl text-pretty text-3xl font-semibold leading-[1.12] tracking-[-0.04em] text-stone-950 sm:text-4xl lg:max-w-3xl lg:text-5xl">
          The worst of the internet has never been easier to reach.
        </h2>

        <EntryPointList />
      </div>
    </HomeSectionRails>

    <div className="border-y border-stone-200/80">
      <HomeSectionRails className="bg-white">
        <SolutionCard />
      </HomeSectionRails>
    </div>
  </section>
);

export default HomeProblemSection;

const SolutionCard: React.FC = () => (
  <div className="relative w-full overflow-hidden px-6 py-20 text-center sm:px-12 lg:px-20 lg:py-28">
    <img
      src="/home/grainy-gradient.webp"
      srcSet="/home/grainy-gradient-1000.webp 1000w, /home/grainy-gradient-1280.webp 1280w, /home/grainy-gradient-1600.webp 1600w, /home/grainy-gradient.webp 2000w"
      sizes="(min-width: 1280px) 1280px, 100vw"
      alt=""
      width={2000}
      height={2000}
      loading="lazy"
      decoding="async"
      className="pointer-events-none absolute inset-0 z-0 size-full object-fill opacity-20"
    />
    <div
      aria-hidden
      className="pointer-events-none absolute inset-0 z-0 bg-[url('/home/dot-noise-pattern.svg')] bg-[length:1440px_1440px] bg-repeat"
      style={{
        WebkitMaskImage: `linear-gradient(to bottom, transparent, black)`,
        maskImage: `linear-gradient(to bottom, transparent, black)`,
      }}
    />
    <div
      aria-hidden
      className="pointer-events-none absolute inset-0 z-0 bg-[radial-gradient(circle_at_center,white_0%,rgba(255,255,255,0.85)_30%,rgba(255,255,255,0)_70%)]"
    />
    <div
      aria-hidden
      className="relative z-10 mx-auto flex items-center justify-center gap-5"
    >
      <img
        src="/home/safety-padlock.svg"
        alt=""
        width={317}
        height={370}
        loading="lazy"
        decoding="async"
        className="h-11 w-auto sm:h-[3.75rem]"
      />
      <img
        src="/home/safety-logo-stone.svg"
        alt=""
        width={365}
        height={365}
        loading="lazy"
        decoding="async"
        className="size-12 shrink-0 sm:size-16"
      />
      <img
        src="/home/safety-shield.svg"
        alt=""
        width={290}
        height={362}
        loading="lazy"
        decoding="async"
        className="h-11 w-auto sm:h-[3.75rem]"
      />
    </div>
    <h3
      className={`${rubik.className} relative z-10 mx-auto mt-10 max-w-4xl text-3xl font-semibold leading-[1.12] tracking-[-0.04em] text-stone-950 sm:text-5xl`}
    >
      Gertrude makes devices
      <span className="mt-3 block">
        <SolutionSafetyPhrase />
      </span>
    </h3>
    <p className="relative z-10 mx-auto mt-8 max-w-3xl text-lg leading-7 text-transparent bg-gradient-to-r from-violet-950/70 to-fuchsia-950/70 bg-clip-text sm:text-xl sm:leading-8">
      Keeping pornography and other harmful content off your devices shouldn’t be a losing
      battle. Gertrude gives you strict control over what’s accessible, closes the
      loopholes other tools leave open, and provides real accountability for how devices
      are used.
    </p>
  </div>
);

const SolutionSafetyPhrase: React.FC = () => {
  const phraseRef = React.useRef<HTMLSpanElement>(null);
  const hasEntered = useIntersectionVisibility(phraseRef, 0.6);

  return (
    <span
      ref={phraseRef}
      className={`${
        rubik.className
      } home-solution-phrase rounded-3xl inline-flex items-center font-semibold leading-[1.45em] tracking-[-0.035em] ${
        hasEntered ? `home-solution-phrase-visible` : ``
      }`}
    >
      <span aria-hidden className="home-solution-phrase-icon">
        <span className="home-solution-phrase-icon-graphic">
          <ShieldCheckIcon className="size-[0.85em] sm:size-10" />
        </span>
      </span>
      <span>truly safe.</span>
    </span>
  );
};

const EntryPointList: React.FC = () => {
  const listRef = React.useRef<HTMLUListElement>(null);
  const hasEntered = useIntersectionVisibility(listRef, 0.2);
  const [canRepel, setCanRepel] = React.useState(false);
  const [letters, setLetters] = React.useState<RepellingLetterPosition[][]>([]);
  const pointer = useMotionValue<RepulsionPointer | null>(null);
  const lastPointer = React.useRef<RepulsionPointer | null>(null);
  const enabled = hasEntered && canRepel;

  React.useEffect(() => {
    const hover = window.matchMedia(
      `(hover: hover) and (pointer: fine) and (min-width: 640px)`,
    );
    const reducedMotion = window.matchMedia(`(prefers-reduced-motion: reduce)`);
    const updateMotion = (): void => {
      const allowed = hover.matches && !reducedMotion.matches;
      setCanRepel(allowed);
      if (!allowed) {
        pointer.set(null);
        setLetters([]);
      }
    };
    updateMotion();
    hover.addEventListener(`change`, updateMotion);
    reducedMotion.addEventListener(`change`, updateMotion);
    return () => {
      hover.removeEventListener(`change`, updateMotion);
      reducedMotion.removeEventListener(`change`, updateMotion);
    };
  }, [pointer]);

  React.useLayoutEffect(() => {
    const list = listRef.current;
    if (!enabled || !list) return;
    let active = true;
    const reset = (): void => pointer.set(null);
    const measure = (): void => {
      if (!active) return;
      reset();
      const listBounds = list.getBoundingClientRect();
      const fontSize = Number.parseFloat(getComputedStyle(list).fontSize);
      const positions = Array.from(
        list.querySelectorAll<HTMLElement>(`[data-entry-point-source]`),
      ).map((source) => {
        const text = source.firstChild;
        const item = source.parentElement;
        if (!text || !item) return [];
        const bounds = item.getBoundingClientRect();
        const transform = new DOMMatrix(getComputedStyle(item).transform);
        const range = document.createRange();
        let offset = 0;
        let firstTop: number | undefined;
        return Array.from(source.textContent ?? ``).map((character) => {
          const index = offset;
          range.setStart(text, offset);
          offset += character.length;
          range.setEnd(text, offset);
          const rect = range.getBoundingClientRect();
          firstTop ??= rect.top;
          return {
            character,
            index,
            left: rect.left - bounds.left,
            top: rect.top - firstTop,
            centerX: rect.left - listBounds.left - transform.m41 + rect.width / 2,
            centerY: rect.top - listBounds.top - transform.m42 + rect.height / 2,
            fontSize,
          };
        });
      });
      setLetters(positions);
    };
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(list);
    void document.fonts.ready.then(measure);
    document.fonts.addEventListener(`loadingdone`, measure);
    window.addEventListener(`scroll`, reset, { passive: true });
    window.addEventListener(`blur`, reset);
    return () => {
      active = false;
      observer.disconnect();
      reset();
      document.fonts.removeEventListener(`loadingdone`, measure);
      window.removeEventListener(`scroll`, reset);
      window.removeEventListener(`blur`, reset);
    };
  }, [enabled, pointer]);

  const repel = (event: React.PointerEvent<HTMLUListElement>): void => {
    if (!enabled || event.pointerType !== `mouse`) return;
    if (event.buttons !== 0) {
      lastPointer.current = { x: event.clientX, y: event.clientY };
      pointer.set(null);
      return;
    }
    const previous = lastPointer.current;
    if (
      previous &&
      Math.hypot(event.clientX - previous.x, event.clientY - previous.y) < 0.5
    )
      return;
    lastPointer.current = { x: event.clientX, y: event.clientY };
    const bounds = event.currentTarget.getBoundingClientRect();
    pointer.set({ x: event.clientX - bounds.left, y: event.clientY - bounds.top });
  };

  const release = (): void => {
    lastPointer.current = null;
    pointer.set(null);
  };

  return (
    <ul
      ref={listRef}
      className="mt-10 flex max-w-6xl cursor-default select-none flex-wrap gap-x-[0.3em] gap-y-[0.12em] text-2xl font-medium leading-[1.2] tracking-[-0.035em] text-stone-400 sm:mt-16 sm:text-4xl lg:text-5xl"
      onPointerMove={repel}
      onPointerDown={() => pointer.set(null)}
      onPointerLeave={release}
      onPointerCancel={release}
    >
      {entryPoints.map((entryPoint, index) => (
        <li
          key={entryPoint}
          className={`relative ${
            hasEntered
              ? `home-problem-entry-point`
              : `home-js-reveal text-stone-400 opacity-0 motion-reduce:opacity-100`
          }`}
          style={{ animationDelay: hasEntered ? `${index * 100}ms` : `0ms` }}
        >
          <span
            data-entry-point-source
            className={enabled && letters[index]?.length ? `text-transparent` : undefined}
          >
            {entryPoint}
          </span>
          {enabled && letters[index] && (
            <span
              aria-hidden
              className="pointer-events-none absolute inset-0 select-none"
            >
              {letters[index].map((letter) => (
                <RepellingLetter key={letter.index} letter={letter} pointer={pointer} />
              ))}
            </span>
          )}
        </li>
      ))}
    </ul>
  );
};

interface RepulsionPointer {
  x: number;
  y: number;
}

interface RepellingLetterPosition {
  character: string;
  index: number;
  left: number;
  top: number;
  centerX: number;
  centerY: number;
  fontSize: number;
}

interface RepellingLetterProps {
  letter: RepellingLetterPosition;
  pointer: MotionValue<RepulsionPointer | null>;
}

const letterSpring = { stiffness: 240, damping: 18, mass: 0.75 };

const RepellingLetter: React.FC<RepellingLetterProps> = ({ letter, pointer }) => {
  const x = useSpring(0, letterSpring);
  const y = useSpring(0, letterSpring);
  const rotate = useSpring(0, letterSpring);
  const displacement = useTransform(() => Math.hypot(x.get(), y.get()));
  const violet = useTransform(displacement, [0, letter.fontSize * 1.35], [0, 100]);
  const color = useMotionTemplate`color-mix(in srgb, var(--home-problem-entry-color) calc(100% - ${violet}%), #7c3aed ${violet}%)`;

  useMotionValueEvent(pointer, `change`, (cursor) => {
    let offsetX = 0;
    let offsetY = 0;
    if (cursor) {
      const dx = letter.centerX - cursor.x;
      const dy = letter.centerY - cursor.y;
      const distance = Math.hypot(dx, dy);
      const radius = letter.fontSize * 3.2;
      if (distance < radius) {
        const angle = distance < 1 ? letter.index * 2.4 : Math.atan2(dy, dx);
        const force = letter.fontSize * 1.35 * (1 - distance / radius) ** 2;
        offsetX = Math.cos(angle) * force;
        offsetY = Math.sin(angle) * force;
      }
    }
    x.set(offsetX);
    y.set(offsetY);
    rotate.set(offsetX * 0.14 - offsetY * 0.06);
  });

  return (
    <motion.span
      className="home-problem-letter pointer-events-none absolute whitespace-pre"
      style={{ left: letter.left, top: letter.top, x, y, rotate, color }}
    >
      {letter.character}
    </motion.span>
  );
};
