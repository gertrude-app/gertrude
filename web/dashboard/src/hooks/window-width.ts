import { useState, useEffect } from 'react';

export default function useWindowWidth(): number {
  const [width, setWidth] = useState(window.innerWidth);

  useEffect(() => {
    const debouncedHandler = debounce(() => setWidth(window.innerWidth), 250);
    window.addEventListener(`resize`, debouncedHandler);
    return () => window.removeEventListener(`resize`, debouncedHandler);
  }, []);

  return width;
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
