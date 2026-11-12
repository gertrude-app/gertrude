'use client';

import { Popover } from '@base-ui/react/popover';
import {
  type HTMLMotionProps,
  type MotionValue,
  motion,
  useMotionTemplate,
  useMotionValue,
  useMotionValueEvent,
  useSpring,
  useTransform,
  useVelocity,
} from 'framer-motion';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import HomeAppIcon from '@/components/home/HomeAppIcon';
import HomeButtonLink from '@/components/home/HomeButtonLink';
import { useHeroEntranceReady } from '@/components/home/HomeHeroEntrance';
import HomeHeroRise from '@/components/home/HomeHeroRise';
import { heroSequence } from '@/lib/home-hero-sequence';
import { revealSpring, useMotionPreferences } from '@/lib/home-motion';
import { homeProducts } from '@/lib/home-products';

const apps = [
  { ...homeProducts.music, tilt: `-rotate-12`, rotation: -12, raised: false },
  { ...homeProducts.blocker, tilt: `-rotate-[4deg]`, rotation: -4, raised: true },
  { ...homeProducts.podcasts, tilt: `rotate-[4deg]`, rotation: 4, raised: true },
  { ...homeProducts.mac, tilt: `rotate-12`, rotation: 12, raised: false },
] as const;

type HeroApp = (typeof apps)[number];

const travelSpring = { stiffness: 320, damping: 26, mass: 1.1 };
const cardOffset = 16;
const cardCollisionPadding = 48;

function useRowCardSide(
  open: boolean,
  rowRef: React.RefObject<HTMLUListElement | null>,
  popupRef: React.RefObject<HTMLDivElement | null>,
): `top` | `bottom` {
  const [side, setSide] = React.useState<`top` | `bottom`>(`top`);

  React.useLayoutEffect(() => {
    if (!open) return;
    const update = (): void => {
      const triggers = rowRef.current?.querySelectorAll(`button`) ?? [];
      const rowTop = Math.min(...[...triggers].map((t) => t.getBoundingClientRect().top));
      const content = popupRef.current?.querySelector(`.home-hero-app-viewport`);
      const cardHeight = content ? content.scrollHeight + 2 : 200;
      const room = rowTop - cardOffset - cardCollisionPadding;
      setSide(room >= cardHeight ? `top` : `bottom`);
    };
    update();
    const frame = requestAnimationFrame(update);
    window.addEventListener(`scroll`, update, { passive: true });
    window.addEventListener(`resize`, update);
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener(`scroll`, update);
      window.removeEventListener(`resize`, update);
    };
  }, [open, popupRef, rowRef]);

  return side;
}

type SpringPositionerProps = React.ComponentPropsWithRef<`div`> & {
  x: MotionValue<number>;
  y: MotionValue<number>;
  reducedMotion: boolean;
};

const SpringPositioner: React.FC<SpringPositionerProps> = ({
  style,
  x,
  y,
  reducedMotion,
  ...props
}) => {
  const initialized = React.useRef(false);
  const previousAxis = React.useRef<string | undefined>(undefined);
  const axis = style?.bottom === undefined ? `top` : `bottom`;
  const left = Number(style?.left ?? 0);
  const vertical = Number(style?.[axis] ?? 0);
  const positioned = style?.opacity !== 0;

  React.useLayoutEffect(() => {
    if (!positioned) return;
    if (!initialized.current || reducedMotion) x.jump(left);
    else x.set(left);
    if (!initialized.current || reducedMotion || previousAxis.current !== axis) {
      y.jump(vertical);
    } else {
      y.set(vertical);
    }
    initialized.current = true;
    previousAxis.current = axis;
  }, [axis, left, positioned, reducedMotion, vertical, x, y]);

  return (
    <motion.div
      {...(props as HTMLMotionProps<`div`>)}
      style={{
        ...style,
        left: x,
        top: axis === `top` ? y : `auto`,
        bottom: axis === `bottom` ? y : `auto`,
      }}
    />
  );
};

type SpringArrowProps = React.ComponentPropsWithRef<`div`> & {
  originX: MotionValue<number>;
  reducedMotion: boolean;
};

const SpringArrow: React.FC<SpringArrowProps> = ({
  style,
  originX,
  reducedMotion,
  ...props
}) => {
  const initialized = React.useRef(false);
  const center = Number(style?.left ?? 0) + 6;
  const positioned = style?.left !== undefined;
  const left = useTransform(originX, (value) => value - 6);

  React.useLayoutEffect(() => {
    if (!positioned) return;
    if (!initialized.current || reducedMotion) originX.jump(center);
    else originX.set(center);
    initialized.current = true;
  }, [center, originX, positioned, reducedMotion]);

  return <motion.div {...(props as HTMLMotionProps<`div`>)} style={{ ...style, left }} />;
};

interface HeroAppPopoverProps {
  app: HeroApp;
  open: boolean;
  onClosed: () => void;
  rowRef: React.RefObject<HTMLUListElement | null>;
  reducedMotion: boolean;
}

const HeroAppPopover: React.FC<HeroAppPopoverProps> = ({
  app,
  open,
  onClosed,
  rowRef,
  reducedMotion,
}) => {
  const x = useSpring(0, travelSpring);
  const y = useSpring(0, travelSpring);
  const originX = useSpring(128, travelSpring);
  const rotation = useSpring(app.rotation - 3, travelSpring);
  const targetRotation = useMotionValue(app.rotation);
  const velocity = useVelocity(rotation);
  const acceleration = useTransform(
    () =>
      (travelSpring.stiffness * (targetRotation.get() - rotation.get()) -
        travelSpring.damping * velocity.get()) /
      travelSpring.mass,
  );
  const inertia = useSpring(0, { stiffness: 300, damping: 22, mass: 1 });
  const popupRef = React.useRef<HTMLDivElement>(null);
  const side = useRowCardSide(open, rowRef, popupRef);
  const rotate = useTransform(() => {
    const angle = rotation.get();
    if (reducedMotion) return angle;
    const hanging = popupRef.current?.getAttribute(`data-side`) === `bottom`;
    const swing = hanging ? -inertia.get() : inertia.get();
    const limit = window.innerWidth < 640 ? 15.5 : 30;
    const room = swing >= 0 ? limit - angle : limit + angle;
    return angle + Math.tanh(swing / room) * room;
  });
  const transformOrigin = useMotionTemplate`${originX}px var(--home-hero-app-pivot)`;

  useMotionValueEvent(acceleration, `change`, (value) => {
    if (!reducedMotion) inertia.set(24 * Math.tanh((-value * 0.013) / 24));
  });

  React.useLayoutEffect(() => {
    targetRotation.set(app.rotation);
    if (reducedMotion) {
      rotation.jump(app.rotation);
      inertia.jump(0);
    } else {
      rotation.set(app.rotation);
    }
  }, [app.rotation, inertia, reducedMotion, rotation, targetRotation]);

  return (
    <Popover.Positioner
      side={side}
      sideOffset={cardOffset}
      collisionAvoidance={{ side: `none`, align: `shift` }}
      collisionPadding={cardCollisionPadding}
      arrowPadding={16}
      className="home-hero-app-positioner z-[60] h-[var(--positioner-height)] w-[var(--positioner-width)] outline-none"
      render={<SpringPositioner x={x} y={y} reducedMotion={reducedMotion} />}
    >
      <Popover.Popup
        ref={popupRef}
        initialFocus={(interaction) => interaction === `keyboard`}
        className="home-hero-app-popup flex h-[var(--popup-height,auto)] max-h-[var(--available-height)] w-64 max-w-[calc(100vw-6rem)] flex-col rounded-2xl border border-stone-200 bg-white text-stone-800 shadow-xl shadow-stone-900/10 outline-none"
        render={(props, { side }) => {
          const offset = side === `bottom` ? -12 : 12;
          return (
            <motion.div
              {...(props as HTMLMotionProps<`div`>)}
              initial={reducedMotion ? false : { opacity: 0, scale: 0.2, y: offset }}
              animate={{
                opacity: open ? 1 : 0,
                scale: open ? 1 : 0.2,
                y: open ? 0 : offset,
              }}
              transition={
                reducedMotion
                  ? { duration: 0 }
                  : {
                      scale: revealSpring,
                      y: revealSpring,
                      opacity: { duration: 0.13, ease: `easeOut` },
                    }
              }
              style={{ ...props.style, rotate, transformOrigin }}
              onAnimationComplete={() => {
                if (!open) onClosed();
              }}
            />
          );
        }}
      >
        <Popover.Arrow
          className="home-hero-app-arrow absolute bottom-[-6.5px] size-3 rotate-45 rounded-br-[4px] border-b border-r border-stone-200 bg-white data-[side=bottom]:bottom-auto data-[side=bottom]:top-[-6.5px] data-[side=bottom]:rounded-br-none data-[side=bottom]:rounded-tl-[4px] data-[side=bottom]:border-b-0 data-[side=bottom]:border-r-0 data-[side=bottom]:border-l data-[side=bottom]:border-t"
          render={<SpringArrow originX={originX} reducedMotion={reducedMotion} />}
        />
        <Popover.Viewport className="home-hero-app-viewport relative min-h-0 overflow-x-hidden overflow-y-auto overscroll-contain rounded-[inherit]">
          <Popover.Title className="text-base font-medium tracking-[-0.02em] text-stone-950">
            {app.title}
          </Popover.Title>
          <Popover.Description className="mt-1 text-sm leading-6 text-stone-600">
            {app.description}
          </Popover.Description>
          <HomeButtonLink
            href={`learnMoreHref` in app ? app.learnMoreHref : app.href}
            variant="secondary"
            className="mt-4 w-full"
            aria-label={`Learn more about ${app.title}`}
          >
            Learn more
            <ArrowRightIcon aria-hidden="true" className="size-3.5" />
          </HomeButtonLink>
        </Popover.Viewport>
      </Popover.Popup>
    </Popover.Positioner>
  );
};

const HomeHeroApps: React.FC = () => {
  const ready = useHeroEntranceReady();
  const { reducedMotion } = useMotionPreferences();
  const [open, setOpen] = React.useState(false);
  const [interactive, setInteractive] = React.useState(false);
  const actionsRef = React.useRef<Popover.Root.Actions | null>(null);
  const rowRef = React.useRef<HTMLUListElement>(null);
  const onClosed = React.useCallback(() => actionsRef.current?.unmount(), []);

  React.useEffect(() => {
    if (!ready) return;
    if (reducedMotion) {
      setInteractive(true);
      return;
    }
    const timer = setTimeout(() => setInteractive(true), heroSequence.apps);
    return () => clearTimeout(timer);
  }, [ready, reducedMotion]);

  return (
    <Popover.Root<HeroApp>
      actionsRef={actionsRef}
      onOpenChange={(nextOpen, details) => {
        if (!nextOpen) details.preventUnmountOnClose();
        setOpen(nextOpen);
      }}
    >
      {({ payload }) => (
        <>
          <ul
            ref={rowRef}
            aria-label="Gertrude apps"
            className={`mb-8 flex items-center -space-x-1 lg:mb-12 ${interactive ? `` : `pointer-events-none`}`}
          >
            {apps.map((app, index) => (
              <li
                key={app.href}
                className={app.raised ? `relative z-10 -mt-4` : `relative z-0`}
              >
                <Popover.Trigger
                  type="button"
                  payload={app}
                  openOnHover
                  delay={40}
                  closeDelay={180}
                  aria-label={`About ${app.title}`}
                  className="home-hero-app-trigger group block size-14 cursor-pointer rounded-[26%] outline-none focus-visible:ring-2 focus-visible:ring-violet-400 focus-visible:ring-offset-4"
                >
                  <HomeHeroRise
                    className="pointer-events-none block"
                    distance={32}
                    delay={heroSequence.apps + index * heroSequence.appStagger}
                  >
                    <span className="block transition-transform duration-300 ease-out group-hover:-translate-y-1 group-focus-visible:-translate-y-1 group-data-[popup-open]:-translate-y-1 motion-reduce:transition-none">
                      <HomeAppIcon src={app.iconSrc} alt="" className={app.tilt} />
                    </span>
                  </HomeHeroRise>
                </Popover.Trigger>
              </li>
            ))}
          </ul>
          <Popover.Portal>
            {payload && (
              <HeroAppPopover
                app={payload}
                open={open}
                onClosed={onClosed}
                rowRef={rowRef}
                reducedMotion={reducedMotion}
              />
            )}
          </Popover.Portal>
        </>
      )}
    </Popover.Root>
  );
};

export default HomeHeroApps;
