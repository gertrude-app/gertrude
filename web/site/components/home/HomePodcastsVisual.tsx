'use client';

import { CheckIcon, DeleteIcon, LockKeyholeIcon, RotateCcwIcon } from 'lucide-react';
import React from 'react';
import type { PodcastDemoFrame, PodcastShowId } from '@/lib/home-podcasts-demo';
import {
  finalPodcastDemoFrame,
  initialAllowedShowIds,
  initialPodcastDemoFrame,
  podcastCatalogIds,
  podcastDemoFrames,
  podcastDemoPin,
  podcastFlightDuration,
  podcastFlightStagger,
  podcastShows,
  selectedPodcastShowIds,
} from '@/lib/home-podcasts-demo';

const HomePodcastsVisual: React.FC<{ isDark: boolean }> = ({ isDark }) => {
  const visualRef = React.useRef<HTMLElement>(null);
  const chooserRef = React.useRef<HTMLDivElement>(null);
  const flightLayerRef = React.useRef<HTMLDivElement>(null);
  const timers = React.useRef<ReturnType<typeof setTimeout>[]>([]);
  const flights = React.useRef<{ animation: Animation; element: HTMLElement }[]>([]);
  const reducedMotionRef = React.useRef(false);
  const [reducedMotion, setReducedMotion] = React.useState(false);
  const [frame, setFrame] = React.useState<PodcastDemoFrame>(initialPodcastDemoFrame);
  const [arrived, setArrived] = React.useState<Set<PodcastShowId>>(new Set());

  const clearFlights = React.useCallback((): void => {
    flights.current.forEach(({ animation, element }) => {
      animation.onfinish = null;
      animation.cancel();
      element.remove();
    });
    flights.current = [];
  }, []);

  const cancel = React.useCallback((): void => {
    timers.current.forEach(clearTimeout);
    timers.current = [];
    clearFlights();
  }, [clearFlights]);

  const settle = React.useCallback((): void => {
    cancel();
    setFrame(finalPodcastDemoFrame);
    setArrived(new Set(selectedPodcastShowIds));
  }, [cancel]);

  const play = React.useCallback((): void => {
    cancel();
    if (reducedMotionRef.current) {
      settle();
      return;
    }
    setArrived(new Set());
    setFrame(initialPodcastDemoFrame);
    timers.current = podcastDemoFrames
      .slice(1)
      .map((next) => setTimeout(() => setFrame(next), next.at));
  }, [cancel, settle]);

  React.useEffect(() => {
    const chooser = chooserRef.current;
    if (!chooser) return;
    const media = window.matchMedia(`(prefers-reduced-motion: reduce)`);
    const updateMotion = (): void => {
      reducedMotionRef.current = media.matches;
      setReducedMotion(media.matches);
      if (media.matches) settle();
    };
    updateMotion();
    media.addEventListener(`change`, updateMotion);
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting) return;
        play();
        observer.disconnect();
      },
      { threshold: 0.75 },
    );
    observer.observe(chooser);
    return () => {
      cancel();
      observer.disconnect();
      media.removeEventListener(`change`, updateMotion);
    };
  }, [cancel, play, settle]);

  React.useEffect(() => {
    if (frame.phase !== `transferring`) return;
    const visual = visualRef.current;
    const layer = flightLayerRef.current;
    if (!visual || !layer) return;
    const origin = layer.getBoundingClientRect();
    selectedPodcastShowIds.forEach((id, index) => {
      const source = visual.querySelector<HTMLElement>(`[data-podcasts-source="${id}"]`);
      const target = visual.querySelector<HTMLElement>(`[data-podcasts-target="${id}"]`);
      if (!source || !target) return;
      const from = source.getBoundingClientRect();
      const to = target.getBoundingClientRect();
      if (from.width === 0 || to.width === 0) return;
      const element = source.cloneNode(true) as HTMLElement;
      element.removeAttribute(`data-podcasts-source`);
      Object.assign(element.style, {
        position: `absolute`,
        left: `${from.left - origin.left}px`,
        top: `${from.top - origin.top}px`,
        width: `${from.width}px`,
        height: `${from.height}px`,
        opacity: `1`,
        transformOrigin: `top left`,
        boxShadow: `0 20px 50px -12px rgba(0, 0, 0, 0.45)`,
      });
      layer.appendChild(element);
      const animation = element.animate(
        [
          { transform: `translate(0, 0) scale(1)` },
          {
            transform: `translate(${to.left - from.left}px, ${to.top - from.top}px) scale(${to.width / from.width}, ${to.height / from.height})`,
          },
        ],
        {
          duration: podcastFlightDuration,
          delay: index * podcastFlightStagger,
          easing: `cubic-bezier(0.22, 1, 0.36, 1)`,
          fill: `both`,
        },
      );
      animation.onfinish = () => {
        setArrived((current) => new Set([...current, id]));
        element.remove();
      };
      flights.current.push({ animation, element });
    });
    window.addEventListener(`resize`, settle);
    return () => {
      clearFlights();
      window.removeEventListener(`resize`, settle);
    };
  }, [frame.phase, clearFlights, settle]);

  const isPin = frame.phase === `pin`;
  const isSettled = frame.phase === `settled`;
  const hasDeparted = frame.phase === `transferring` || isSettled;
  const selected = new Set<PodcastShowId>(
    selectedPodcastShowIds.slice(0, frame.selectedCount),
  );

  return (
    <figure
      ref={visualRef}
      data-podcasts-phase={frame.phase}
      className={`home-podcasts-demo relative mx-auto mt-16 max-w-5xl sm:mt-20 ${isDark ? `home-podcasts-demo-dark` : ``}`}
    >
      <figcaption className="sr-only">
        Your six-digit PIN unlocks a catalog of shows. Selected shows move into the
        allowed library, where your child can listen to them and their future episodes.
        Real podcasts and two classic audiobook feeds are shown as examples.
      </figcaption>
      <div
        aria-hidden="true"
        className="grid grid-cols-1 gap-6 text-[color:var(--podcast-ink)] md:grid-cols-2 md:gap-10"
      >
        <div className="min-w-0 p-5 sm:p-8">
          <h4 className="text-xl font-semibold tracking-tight sm:text-2xl">
            Choose Shows
          </h4>
          <p className="mt-2 flex items-center gap-1.5 text-xs text-[color:var(--podcast-muted)]">
            <LockKeyholeIcon className="size-3 shrink-0" />
            Your PIN unlocks new shows
          </p>
          <div ref={chooserRef} className="relative mt-6 h-[22rem] sm:h-[27rem]">
            <div
              className={`absolute inset-0 flex items-center justify-center transition-[opacity,transform] duration-500 ${isPin ? `translate-y-0 opacity-100` : `pointer-events-none -translate-y-3 opacity-0`}`}
            >
              <PodcastKeypad digits={frame.pinDigits} />
            </div>
            <div
              className={`absolute inset-0 flex items-center justify-center transition-[opacity,transform] duration-500 ${isPin ? `pointer-events-none translate-y-3 opacity-0` : isSettled ? `translate-y-0 opacity-40` : `translate-y-0 opacity-100`}`}
            >
              <div
                className="grid w-full max-w-[21rem] grid-cols-3 gap-x-3 gap-y-4 sm:gap-x-4"
                data-podcasts-catalog
              >
                {podcastCatalogIds.map((id) => (
                  <div key={id} className="min-w-0">
                    <div
                      className={`relative rounded-xl transition-shadow duration-300 ${selected.has(id) && !hasDeparted ? `ring-2 ring-[var(--podcast-accent)] ring-offset-4 ring-offset-[var(--podcast-surface)]` : ``}`}
                    >
                      <div className="pointer-events-none absolute inset-0 flex items-center justify-center rounded-xl border border-dashed border-[var(--podcast-line)]">
                        {isSettled && selected.has(id) && (
                          <CheckIcon className="size-5 text-[color:var(--podcast-muted)]" />
                        )}
                      </div>
                      <div
                        data-podcasts-source={id}
                        className="relative aspect-square rounded-xl"
                        style={{ opacity: hasDeparted && selected.has(id) ? 0 : 1 }}
                      >
                        <PodcastArtwork id={id} />
                      </div>
                      <span
                        className={`absolute -right-1.5 -top-1.5 flex size-5 items-center justify-center rounded-full bg-[var(--podcast-accent)] text-[color:var(--podcast-surface)] transition-[opacity,transform] duration-300 ${selected.has(id) && !hasDeparted ? `scale-100 opacity-100` : `scale-50 opacity-0`}`}
                      >
                        <CheckIcon className="size-3" strokeWidth={3} />
                      </span>
                    </div>
                    <p className="mt-2 truncate text-[10px] font-medium sm:text-[11px]">
                      {podcastShows[id].title}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
        <div className="min-w-0 p-5 sm:p-8">
          <h4 className="text-xl font-semibold tracking-tight sm:text-2xl">
            Allowed Shows
          </h4>
          <p className="mt-2 text-xs text-[color:var(--podcast-muted)]">
            Ready for them to enjoy
          </p>
          <div className="mt-6 flex min-h-[17rem] items-center justify-center sm:h-[27rem]">
            <div
              className="grid w-full max-w-[21rem] grid-cols-2 gap-x-4 gap-y-5"
              data-podcasts-allowed
            >
              {[...initialAllowedShowIds, ...selectedPodcastShowIds].map((id, index) => {
                const visible =
                  index < initialAllowedShowIds.length || isSettled || arrived.has(id);
                return (
                  <div key={id} className="min-w-0">
                    <div
                      data-podcasts-target={id}
                      className="relative aspect-square rounded-xl"
                    >
                      <div
                        className={`absolute inset-0 rounded-xl border border-dashed border-[var(--podcast-line)] transition-opacity duration-300 ${visible ? `opacity-0` : `opacity-100`}`}
                      />
                      <div className="size-full" style={{ opacity: visible ? 1 : 0 }}>
                        <PodcastArtwork id={id} />
                      </div>
                    </div>
                    <p
                      className={`mt-2 truncate text-xs font-medium transition-opacity duration-300 sm:text-sm ${visible ? `opacity-100` : `opacity-0`}`}
                    >
                      {podcastShows[id].title}
                    </p>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>
      <div
        ref={flightLayerRef}
        data-podcasts-flights
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 z-20"
      />
      <div className="mt-6 flex items-start justify-between gap-4 text-[color:var(--podcast-muted)]">
        <p className="max-w-lg text-xs leading-5 sm:text-sm">
          <span className="font-medium text-[color:var(--podcast-ink)]">
            You choose the shows.
          </span>
          {` `}New episodes arrive automatically.
        </p>
        <button
          type="button"
          onClick={play}
          disabled={reducedMotion}
          aria-label="Replay the podcast PIN illustration"
          className="relative z-30 flex shrink-0 items-center gap-1.5 rounded-sm py-0.5 text-xs transition-colors hover:text-[color:var(--podcast-accent)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-violet-400 disabled:hidden"
        >
          <RotateCcwIcon className="size-3" /> Replay
        </button>
      </div>
      <p className="mt-3 text-[10px] text-[color:var(--podcast-muted)] opacity-75">
        Example library. Each family chooses its own shows.
      </p>
    </figure>
  );
};

export default HomePodcastsVisual;

const PodcastKeypad: React.FC<{ digits: number }> = ({ digits }) => (
  <div className="w-full max-w-[13rem] text-center">
    <p className="text-base font-medium">Enter your PIN</p>
    <div data-podcasts-pin className="mt-5 flex justify-center gap-3">
      {podcastDemoPin.map((_, index) => (
        <span
          key={index}
          className={`size-2.5 rounded-full border transition-colors duration-150 ${index < digits ? `border-[var(--podcast-accent)] bg-[var(--podcast-accent)]` : `border-[var(--podcast-muted)]`}`}
        />
      ))}
    </div>
    <div className="mt-7 grid grid-cols-3 gap-x-5 gap-y-3">
      {[`1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, null, `0`, `delete`].map((key) => {
        const presses = podcastDemoPin
          .slice(0, digits)
          .filter((digit) => digit === key).length;
        return (
          <span
            key={`${key ?? `blank`}-${presses}`}
            className={`flex aspect-square items-center justify-center rounded-full text-xl font-medium ${key && key !== `delete` ? `bg-[var(--podcast-inset)]` : ``} ${presses > 0 ? `home-podcasts-key-pressed` : ``}`}
          >
            {key === `delete` ? (
              <DeleteIcon className="size-4 text-[color:var(--podcast-muted)]" />
            ) : (
              key
            )}
          </span>
        );
      })}
    </div>
  </div>
);

const PodcastArtwork: React.FC<{ id: PodcastShowId }> = ({ id }) => {
  const show = podcastShows[id];
  const frameColor = `frameColor` in show ? show.frameColor : undefined;
  return (
    <div
      className={`size-full rounded-xl ${frameColor ? `p-1` : `overflow-hidden`}`}
      style={{ backgroundColor: frameColor }}
    >
      <img
        src={show.src}
        alt=""
        width={340}
        height={340}
        decoding="async"
        draggable={false}
        className="block size-full object-contain"
      />
    </div>
  );
};
