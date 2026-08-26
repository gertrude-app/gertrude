import { HStack, VStack } from '@gertrude/ui';
import { Link } from '@tanstack/react-router';
import cx from 'clsx';
import React from 'react';

export type SegmentedTabLink = {
  label: string;
  href: string;
  badgeCount?: number;
  badgeText?: string;
};

interface Props {
  tabs: SegmentedTabLink[];
  selectedHref: string;
  children?: React.ReactNode;
  className?: string;
}

const normalizePath = (path: string): string => {
  const withLeadingSlash = path.startsWith(`/`) ? path : `/${path}`;
  return withLeadingSlash === `/`
    ? withLeadingSlash
    : withLeadingSlash.replace(/\/+$/, ``);
};

// a nested route (`/people/1/ios-settings/<deviceId>`) must still light up its tab,
// and the longest match wins so it beats the parent `/people/1` tab
export const matchingTabHref = (
  tabHrefs: string[],
  currentPath: string,
): string | undefined => {
  const current = normalizePath(currentPath);
  return tabHrefs
    .map(normalizePath)
    .filter((href) => current === href || current.startsWith(`${href}/`))
    .sort((a, b) => b.length - a.length)[0];
};

const SegmentedTabLinks: React.FC<Props> = ({
  tabs,
  selectedHref,
  children,
  className,
}) => {
  const normalizedSelectedHref = normalizePath(selectedHref);
  const selectedTabHref = React.useMemo(
    () =>
      matchingTabHref(
        tabs.map((tab) => tab.href),
        selectedHref,
      ),
    [tabs, selectedHref],
  );
  const scrollRef = React.useRef<HTMLElement>(null);
  const [canScrollLeft, setCanScrollLeft] = React.useState(false);
  const [canScrollRight, setCanScrollRight] = React.useState(false);

  const updateScrollState = React.useCallback(() => {
    const node = scrollRef.current;

    if (!node) {
      return;
    }

    const maxScrollLeft = node.scrollWidth - node.clientWidth;
    setCanScrollLeft(node.scrollLeft > 1);
    setCanScrollRight(node.scrollLeft < maxScrollLeft - 1);
  }, []);

  React.useEffect(() => {
    const node = scrollRef.current;

    if (!node) {
      return;
    }

    const selectedTab = Array.from(node.children).find(
      (child) => child.getAttribute(`aria-current`) === `page`,
    ) as HTMLElement | undefined;

    if (selectedTab) {
      node.scrollLeft =
        selectedTab.offsetLeft - (node.clientWidth - selectedTab.clientWidth) / 2;
    }

    updateScrollState();

    const resizeObserver = new ResizeObserver(updateScrollState);
    resizeObserver.observe(node);
    Array.from(node.children).forEach((child) => resizeObserver.observe(child));

    return () => resizeObserver.disconnect();
  }, [normalizedSelectedHref, tabs.length, updateScrollState]);

  return (
    <VStack gap={4}>
      <div
        className={cx(
          `relative overflow-hidden rounded-xl bg-stone-100 px-1.5`,
          className,
        )}
      >
        <nav
          ref={scrollRef}
          className="flex py-1.5 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          onScroll={updateScrollState}
        >
          {tabs.map((tab) => {
            const href = normalizePath(tab.href);
            const isSelected = href === selectedTabHref;

            return (
              <Link
                key={`${tab.href}-${tab.label}`}
                to={tab.href}
                className={cx(
                  `flex shrink-0 justify-center rounded-lg border px-3 py-1 text-center whitespace-nowrap outline-none transition-[background-color,border-color,box-shadow,color] duration-100 select-none @sm/main:flex-grow`,
                  isSelected
                    ? `border-stone-200 bg-white text-stone-900 shadow shadow-stone-300/30`
                    : `border-transparent text-stone-600 hover:bg-stone-200/50 focus-visible:bg-stone-200/50`,
                )}
                aria-current={isSelected ? `page` : undefined}
              >
                <HStack as="span" gap={2}>
                  <span>{tab.label}</span>
                  {(tab.badgeCount !== undefined || tab.badgeText !== undefined) && (
                    <span
                      className={cx(
                        `min-w-5 rounded-full px-1.5 py-0.25 text-xs font-medium tabular-nums`,
                        isSelected
                          ? `bg-stone-100 text-stone-700`
                          : `bg-stone-200/70 text-stone-600`,
                      )}
                    >
                      {tab.badgeText ?? tab.badgeCount}
                    </span>
                  )}
                </HStack>
              </Link>
            );
          })}
        </nav>
        {canScrollLeft && (
          <div className="pointer-events-none absolute inset-y-1.5 left-1.5 w-8 bg-gradient-to-r from-stone-100 to-transparent" />
        )}
        {canScrollRight && (
          <div className="pointer-events-none absolute inset-y-1.5 right-1.5 w-8 bg-gradient-to-l from-stone-100 to-transparent" />
        )}
      </div>
      {children}
    </VStack>
  );
};

export default SegmentedTabLinks;
