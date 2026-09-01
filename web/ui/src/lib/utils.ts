import React from 'react';

export function inflect(word: string, count: number): string {
  return count === 1 ? word : `${word}s`;
}

export const normalizePath = (path: string): string => {
  const withLeadingSlash = path.startsWith(`/`) ? path : `/${path}`;
  return withLeadingSlash === `/`
    ? withLeadingSlash
    : withLeadingSlash.replace(/\/+$/, ``);
};

export const useMediaQuery = (query: string): boolean => {
  const [matches, setMatches] = React.useState(false);

  React.useEffect(() => {
    const mediaQueryList = window.matchMedia(query);
    const updateMatches = (): void => setMatches(mediaQueryList.matches);

    updateMatches();
    mediaQueryList.addEventListener(`change`, updateMatches);

    return () => mediaQueryList.removeEventListener(`change`, updateMatches);
  }, [query]);

  return matches;
};
