'use client';

import { UserGroupIcon } from '@heroicons/react/24/outline';
import { motion, useMotionValue, useMotionValueEvent, useSpring } from 'framer-motion';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import type { MotionValue } from 'framer-motion';
import HomeAppIcon from '@/components/home/HomeAppIcon';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import { homeRubik } from '@/components/home/HomeHero';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { useMotionPreferences } from '@/lib/home-motion';
import { useIntersectionVisibility } from '@/lib/hooks';
import { PARENTS_APP_URL } from '@/lib/urls';

const people = [
  {
    name: `Jude`,
    image: `/home/account-avatars/jude.webp`,
    position: `left-[13%] top-9 xl:left-[28%] xl:top-[14%]`,
    size: `size-14 sm:size-16 xl:size-20`,
    tilt: `rotate-[10deg]`,
  },
  {
    name: `Mabel`,
    image: `/home/account-avatars/mabel.webp`,
    position: `left-[88%] top-12 xl:left-[91%] xl:top-[38%]`,
    size: `size-12 sm:size-16 xl:size-20`,
    tilt: `-rotate-[12deg]`,
  },
  {
    name: `Caleb`,
    image: `/home/account-avatars/caleb.webp`,
    position: `left-[48%] top-[calc(100%-4rem)] sm:left-[61%] xl:left-[47%] xl:top-[88%]`,
    size: `size-16 sm:size-20`,
    tilt: `-rotate-[8deg]`,
  },
];

const apps = [
  {
    name: `Mac`,
    icon: `/app-icons/gertrude.webp`,
    position: `left-[50%] top-7 sm:top-10 xl:left-[42%] xl:top-[10%]`,
    size: `[&_img]:size-14 sm:[&_img]:size-16`,
    tilt: `rotate-[5deg]`,
  },
  {
    name: `Blocker`,
    icon: `/app-icons/gertrude.webp`,
    position: `left-[14%] top-[calc(100%-11rem)] xl:left-[33%] xl:top-[81%]`,
    size: `[&_img]:size-12 sm:[&_img]:size-14 xl:[&_img]:size-16`,
    tilt: `-rotate-[5deg]`,
  },
  {
    name: `Music`,
    icon: `/app-icons/music.webp`,
    position: `left-[79%] top-[calc(100%-4.5rem)] xl:left-[70%] xl:top-[94%]`,
    size: `[&_img]:size-[3.25rem] sm:[&_img]:size-16 xl:[&_img]:size-[4.25rem]`,
    tilt: `rotate-[6deg]`,
  },
  {
    name: `Podcasts`,
    icon: `/app-icons/podcasts.webp`,
    position: `left-[12%] top-56 sm:top-[17rem] xl:left-[8%] xl:top-[37%]`,
    size: `[&_img]:size-12 sm:[&_img]:size-14 xl:[&_img]:size-16`,
    tilt: `-rotate-[6deg]`,
  },
];

const deviceSizes = {
  computer: `w-28 sm:w-36 xl:w-44`,
  phone: `w-11 sm:w-14 xl:w-[4.75rem]`,
  tablet: `w-14 sm:w-[4.5rem] xl:w-[5.75rem]`,
};

const devices = [
  {
    name: `MacBook Pro`,
    image: `macbook`,
    width: 500,
    height: 306,
    position: `left-[77%] top-36 sm:top-[9.5rem] xl:left-[83%] xl:top-[17%]`,
    size: deviceSizes.computer,
    tilt: `-rotate-[8deg]`,
  },
  {
    name: `iPhone 18 Pro`,
    image: `iphone`,
    width: 178,
    height: 366,
    position: `left-[43%] top-[calc(100%-10.5rem)] xl:left-[10%] xl:top-[65%]`,
    size: deviceSizes.phone,
    tilt: `rotate-[10deg]`,
  },
  {
    name: `iPad Air`,
    image: `ipad-air`,
    width: 282,
    height: 366,
    position: `left-[87%] top-[calc(100%-10.5rem)] sm:left-[86%] xl:left-[90%] xl:top-[64%]`,
    size: deviceSizes.tablet,
    tilt: `rotate-[7deg]`,
  },
  {
    name: `iMac`,
    image: `imac`,
    width: 456,
    height: 385,
    position: `left-[30%] top-32 sm:top-40 xl:left-[60%] xl:top-[7%]`,
    size: deviceSizes.computer,
    tilt: `rotate-[6deg]`,
  },
  {
    name: `iPhone Air`,
    image: `iphone-air`,
    width: 178,
    height: 366,
    position: `left-[13%] top-[calc(100%-4.5rem)] xl:left-[20%] xl:top-[91%]`,
    size: deviceSizes.phone,
    tilt: `-rotate-[12deg]`,
  },
  {
    name: `iPad Pro`,
    image: `ipad-pro`,
    width: 282,
    height: 366,
    position: `left-[50%] top-60 sm:left-[58%] sm:top-[17rem] xl:left-[10%] xl:top-[14%]`,
    size: deviceSizes.tablet,
    tilt: `-rotate-[11deg]`,
  },
  {
    name: `Mac Studio`,
    image: `mac-studio`,
    width: 456,
    height: 236,
    position: `left-[64%] top-[calc(100%-16rem)] sm:top-[calc(100%-18rem)] xl:left-[86.5%] xl:top-[83%]`,
    size: deviceSizes.computer,
    tilt: `rotate-[8deg]`,
  },
];

const HomeHowItWorksSection: React.FC = () => {
  const stageRef = React.useRef<HTMLDivElement>(null);
  const headingRef = React.useRef<HTMLHeadingElement>(null);
  const finishedItems = React.useRef(new Set<EventTarget>());
  const lastPointer = React.useRef<{ x: number; y: number } | null>(null);
  const pointer = useMotionValue<{ x: number; y: number } | null>(null);
  const { reducedMotion, finePointer } = useMotionPreferences();
  const hasEntered = useIntersectionVisibility(headingRef, 0.6);
  const [phase, setPhase] = React.useState<`highlight` | `orbit` | `complete`>(
    `highlight`,
  );

  React.useEffect(() => {
    if (reducedMotion) setPhase(`complete`);
    pointer.set(null);
    const release = (): void => pointer.set(null);
    window.addEventListener(`scroll`, release, { passive: true });
    window.addEventListener(`resize`, release);
    window.addEventListener(`blur`, release);
    return () => {
      window.removeEventListener(`scroll`, release);
      window.removeEventListener(`resize`, release);
      window.removeEventListener(`blur`, release);
    };
  }, [finePointer, pointer, reducedMotion]);

  const attractOrbit = (event: React.PointerEvent<HTMLDivElement>): void => {
    if (reducedMotion || !finePointer || event.pointerType === `touch`) return;
    const next = { x: event.clientX, y: event.clientY };
    if (lastPointer.current?.x === next.x && lastPointer.current.y === next.y) return;
    lastPointer.current = next;
    pointer.set(next);
  };

  const revealOrbit = (event: React.AnimationEvent<HTMLSpanElement>): void => {
    if (
      event.target !== event.currentTarget ||
      event.animationName !== `home-solution-phrase-reveal` ||
      phase !== `highlight`
    )
      return;

    const stage = stageRef.current;
    if (!stage) return;
    const bounds = stage.getBoundingClientRect();
    const centerX = bounds.left + bounds.width / 2;
    const centerY = bounds.top + bounds.height / 2;
    const items = Array.from(
      stage.querySelectorAll<HTMLElement>(`.home-account-orbit-item`),
    )
      .map((element) => {
        const itemBounds = element.getBoundingClientRect();
        const dx = itemBounds.left + itemBounds.width / 2 - centerX;
        const dy = itemBounds.top + itemBounds.height / 2 - centerY;
        return {
          element,
          dx,
          dy,
          angle: (Math.atan2(dx, -dy) + Math.PI * 2) % (Math.PI * 2),
        };
      })
      .sort((left, right) => left.angle - right.angle);

    items.forEach(({ element, dx, dy }, index) => {
      const inward = Math.min(0.16, 72 / Math.max(1, Math.hypot(dx, dy)));
      element.style.setProperty(`--home-account-orbit-x`, `${-dx * inward}px`);
      element.style.setProperty(`--home-account-orbit-y`, `${-dy * inward}px`);
      element.style.setProperty(`--home-account-orbit-delay`, `${index * 70}ms`);
    });
    finishedItems.current.clear();
    setPhase(`orbit`);
  };

  const finishOrbit = (event: React.AnimationEvent<HTMLDivElement>): void => {
    if (event.animationName !== `home-account-orbit-reveal` || phase !== `orbit`) return;
    finishedItems.current.add(event.target);
    if (finishedItems.current.size === people.length + apps.length + devices.length) {
      setPhase(`complete`);
    }
  };

  const orbitClassName = `home-account-orbit-item home-js-reveal ${
    phase === `complete`
      ? `home-account-orbit-item-visible`
      : phase === `orbit`
        ? `home-account-orbit-item-reveal`
        : ``
  }`;

  return (
    <section
      id="how-it-works"
      aria-labelledby="how-it-works-heading"
      className="scroll-mt-24 border-t border-stone-200/80 bg-white"
    >
      <HomeSectionRails className="bg-white px-6 py-20 sm:px-12 xl:px-[6.5rem] xl:py-24">
        <div
          ref={stageRef}
          onAnimationEnd={finishOrbit}
          onPointerMove={attractOrbit}
          onPointerLeave={() => pointer.set(null)}
          onPointerCancel={() => pointer.set(null)}
          className="relative isolate mx-auto flex min-h-[56rem] items-center justify-center sm:min-h-[60rem] xl:min-h-[46rem]"
        >
          <div className="relative z-10 mx-auto max-w-lg text-center">
            <h2
              ref={headingRef}
              id="how-it-works-heading"
              className={`${homeRubik.className} text-[1.75rem] font-semibold !leading-[1.55] tracking-[-0.035em] text-stone-950 min-[360px]:text-3xl sm:text-4xl xl:text-5xl`}
            >
              <span className="block">One account for your</span>
              {` `}
              <span
                onAnimationEnd={revealOrbit}
                className={`home-solution-phrase home-solution-phrase-compact inline-flex items-center rounded-3xl ${
                  phase !== `highlight`
                    ? `home-account-family-phrase-finished`
                    : hasEntered
                      ? `home-solution-phrase-visible`
                      : ``
                }`}
              >
                <span aria-hidden className="home-solution-phrase-icon">
                  <span className="home-solution-phrase-icon-graphic">
                    <UserGroupIcon className="size-[1em]" />
                  </span>
                </span>
                <span>whole family.</span>
              </span>
            </h2>
            <p className="mt-5 text-lg leading-7 text-stone-600">
              The people you look out for, with the apps they need, on the devices they
              use, all managed from one place.
            </p>
            <HomeButtonLink
              href={`${PARENTS_APP_URL}/signup?v=new_site`}
              size="hero"
              variant="primary"
              className="mt-7"
            >
              Get started free
              <ArrowRightIcon aria-hidden className="size-4" />
            </HomeButtonLink>
          </div>

          <ul
            aria-label="Example people in a shared account"
            className="pointer-events-none absolute inset-0"
          >
            {people.map((person) => (
              <li
                key={person.name}
                aria-label={person.name}
                className={`absolute -translate-x-1/2 -translate-y-1/2 text-center ${person.position}`}
              >
                <OrbitItem
                  className={orbitClassName}
                  pointer={pointer}
                  reducedMotion={reducedMotion}
                  weight={1}
                >
                  <img
                    src={person.image}
                    alt=""
                    width={256}
                    height={256}
                    loading="lazy"
                    decoding="async"
                    className={`mx-auto rounded-full bg-stone-100 object-cover ${person.size} ${person.tilt}`}
                  />
                </OrbitItem>
              </li>
            ))}
          </ul>
          <ul
            aria-label="Apps connected to the account"
            className="pointer-events-none absolute inset-0"
          >
            {apps.map((app) => (
              <li
                key={app.name}
                className={`absolute -translate-x-1/2 -translate-y-1/2 text-center ${app.position} ${app.size}`}
              >
                <OrbitItem
                  className={orbitClassName}
                  pointer={pointer}
                  reducedMotion={reducedMotion}
                  weight={0.75}
                >
                  <HomeAppIcon
                    src={app.icon}
                    alt={app.name}
                    className={`mx-auto ${app.tilt}`}
                  />
                </OrbitItem>
              </li>
            ))}
          </ul>
          <ul
            aria-label="Devices connected to the account"
            className="pointer-events-none absolute inset-0"
          >
            {devices.map((device) => (
              <li
                key={device.name}
                className={`absolute -translate-x-1/2 -translate-y-1/2 ${device.position} ${device.size}`}
              >
                <OrbitItem
                  className={orbitClassName}
                  pointer={pointer}
                  reducedMotion={reducedMotion}
                  weight={1.5}
                >
                  <img
                    src={`/home/account-devices/${device.image}.webp`}
                    alt={device.name}
                    width={device.width}
                    height={device.height}
                    loading="lazy"
                    decoding="async"
                    className={`h-auto w-full ${device.tilt}`}
                  />
                </OrbitItem>
              </li>
            ))}
          </ul>
        </div>
      </HomeSectionRails>
    </section>
  );
};

export default HomeHowItWorksSection;

interface OrbitItemProps {
  children: React.ReactNode;
  className: string;
  pointer: MotionValue<{ x: number; y: number } | null>;
  reducedMotion: boolean;
  weight: number;
}

const OrbitItem: React.FC<OrbitItemProps> = ({
  children,
  className,
  pointer,
  reducedMotion,
  weight,
}) => {
  const ref = React.useRef<HTMLDivElement>(null);
  const spring = { stiffness: 160, damping: 18, mass: weight };
  const x = useSpring(0, spring);
  const y = useSpring(0, spring);
  const rotate = useSpring(0, spring);

  useMotionValueEvent(pointer, `change`, (position) => {
    const anchor = ref.current?.parentElement;
    if (!position || !anchor || reducedMotion) {
      x.set(0);
      y.set(0);
      rotate.set(0);
      return;
    }
    const bounds = anchor.getBoundingClientRect();
    const dx = position.x - bounds.left - bounds.width / 2;
    const dy = position.y - bounds.top - bounds.height / 2;
    const pull = (Math.max(0, 1 - Math.hypot(dx, dy) / 600) * 0.085) / weight;
    x.set(dx * pull);
    y.set(dy * pull);
    rotate.set((dx * 0.12 - dy * 0.035) * pull);
  });

  React.useEffect(() => {
    if (!reducedMotion) return;
    x.jump(0);
    y.jump(0);
    rotate.jump(0);
  }, [reducedMotion, rotate, x, y]);

  return (
    <div ref={ref} className={className}>
      <motion.div style={{ x, y, rotate }}>{children}</motion.div>
    </div>
  );
};
