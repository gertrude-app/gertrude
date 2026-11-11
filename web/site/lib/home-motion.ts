import { useEffect, useState } from 'react';

export const revealSpring = {
  type: `spring`,
  stiffness: 380,
  damping: 23,
  mass: 0.8,
} as const;

export function cssTimeToMilliseconds(value: string): number {
  const time = value.trim();
  return parseFloat(time) * (time.endsWith(`ms`) ? 1 : 1000);
}

export function useMotionPreferences(): {
  reducedMotion: boolean;
  finePointer: boolean;
} {
  const [preferences, setPreferences] = useState({
    reducedMotion: false,
    finePointer: false,
  });

  useEffect(() => {
    const motion = window.matchMedia(`(prefers-reduced-motion: reduce)`);
    const pointer = window.matchMedia(`(hover: hover) and (pointer: fine)`);
    const update = (): void =>
      setPreferences({ reducedMotion: motion.matches, finePointer: pointer.matches });
    update();
    motion.addEventListener(`change`, update);
    pointer.addEventListener(`change`, update);
    return () => {
      motion.removeEventListener(`change`, update);
      pointer.removeEventListener(`change`, update);
    };
  }, []);

  return preferences;
}
