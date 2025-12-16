import { useEffect, useRef, useState } from 'react';

export function useInterval(callback: () => void, delay: number): void {
  const savedCallback = useRef<() => void>();

  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  useEffect(() => {
    function tick(): void {
      if (savedCallback.current) savedCallback.current();
    }
    const id = setInterval(tick, delay);
    return () => clearInterval(id);
  }, [delay]);
}

export function useWindowDimensions(): { width: number; height: number } {
  const [width, setWidth] = useState(1200);
  const [height, setHeight] = useState(800);

  useEffect(() => {
    setWidth(window.innerWidth);
    setHeight(window.innerHeight);
    const debouncedHandler = debounce(() => {
      setWidth(window.innerWidth);
      setHeight(window.innerHeight);
    }, 10);
    window.addEventListener(`resize`, debouncedHandler);
    return () => window.removeEventListener(`resize`, debouncedHandler);
  }, []);

  return { width, height };
}

function debounce(fn: () => unknown, ms: number): () => void {
  let timer: ReturnType<typeof setTimeout> | undefined = undefined;
  return () => {
    if (timer) {
      clearTimeout(timer);
    }
    timer = setTimeout(() => {
      timer = undefined;
      fn();
    }, ms);
  };
}

export function useIntersectionObserver(
  options: IntersectionObserverInit,
  stick?: boolean,
): {
  intersected: boolean;
  ref: React.MutableRefObject<null>;
} {
  const ref = useRef(null);
  const [intersected, setIntersected] = useState(false);
  const hasIntersected = useRef(false);
  const { root, rootMargin, threshold } = options;

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          const coords = entry.target.getBoundingClientRect();
          if (stick && hasIntersected.current) {
            return;
          }
          if (entry.isIntersecting || coords.y < 0) {
            setIntersected(true);
            hasIntersected.current = true;
          } else {
            setIntersected(false);
          }
        });
      },
      { root, rootMargin, threshold },
    );

    if (ref.current) observer.observe(ref.current);

    const cur = ref.current;

    return () => {
      if (cur) observer.unobserve(cur);
    };
  }, [ref, root, rootMargin, threshold, stick]);

  return { intersected, ref };
}

export function useScrollY(): number {
  const [scrollY, setScrollY] = useState(0);

  useEffect(() => {
    const handleScroll = (): void => {
      setScrollY(window.scrollY);
    };
    window.addEventListener(`scroll`, handleScroll);
    return () => window.removeEventListener(`scroll`, handleScroll);
  }, [scrollY]);

  return scrollY;
}

export function useIntersectionVisibility(
  ref: React.RefObject<HTMLElement | null>,
  threshold = 0.5,
): boolean {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry?.isIntersecting) {
          setIsVisible(true);
        }
      },
      { threshold },
    );

    if (ref.current) {
      observer.observe(ref.current);
    }

    return () => observer.disconnect();
  }, [ref, threshold]);

  return isVisible;
}

export function useScrollProgress(
  wrapperRef: React.RefObject<HTMLElement | null>,
): number {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const handleScroll = (): void => {
      if (!wrapperRef.current) return;
      const rect = wrapperRef.current.getBoundingClientRect();
      const wrapperHeight = wrapperRef.current.offsetHeight;
      const viewportHeight = window.innerHeight;
      const scrollableDistance = wrapperHeight - viewportHeight;
      const scrolled = -rect.top;
      const newProgress = Math.max(0, Math.min(1, scrolled / scrollableDistance));
      setProgress(newProgress);
    };

    window.addEventListener(`scroll`, handleScroll);
    return () => window.removeEventListener(`scroll`, handleScroll);
  }, [wrapperRef]);

  return progress;
}

export function useDelayedVisibility(delay: number): boolean {
  const [isVisible, setIsVisible] = useState(delay === 0);

  useEffect(() => {
    if (delay > 0) {
      const timer = setTimeout(() => setIsVisible(true), delay);
      return () => clearTimeout(timer);
    }
  }, [delay]);

  return isVisible;
}
