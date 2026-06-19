import { Link, Outlet, useLocation } from '@tanstack/react-router';
import cx from 'clsx';
import React from 'react';

interface Tab {
  label: string;
  segment: string;
  badgeCount?: number;
}

interface Props {
  basePath: string;
  tabs: Tab[];
  className?: string;
}

const normalizePath = (path: string): string => {
  const withLeadingSlash = path.startsWith(`/`) ? path : `/${path}`;
  return withLeadingSlash === `/`
    ? withLeadingSlash
    : withLeadingSlash.replace(/\/+$/, ``);
};

const normalizeSegment = (segment: string): string => segment.replace(/^\/+|\/+$/g, ``);

const getTabPath = (basePath: string, segment: string): string => {
  const normalizedBasePath = normalizePath(basePath);
  const normalizedSegment = normalizeSegment(segment);

  if (!normalizedSegment) {
    return normalizedBasePath;
  }

  return normalizedBasePath === `/`
    ? `/${normalizedSegment}`
    : `${normalizedBasePath}/${normalizedSegment}`;
};

const SegmentedTabs: React.FC<Props> = ({ basePath, tabs, className }) => {
  const { pathname } = useLocation();
  const normalizedBasePath = normalizePath(basePath);
  const hasBasePathTab = tabs.some((tab) => normalizeSegment(tab.segment) === ``);
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
    updateScrollState();

    const node = scrollRef.current;

    if (!node) {
      return;
    }

    const resizeObserver = new ResizeObserver(updateScrollState);
    resizeObserver.observe(node);
    Array.from(node.children).forEach((child) => resizeObserver.observe(child));

    return () => resizeObserver.disconnect();
  }, [tabs.length, updateScrollState]);

  return (
    <div className="flex flex-col gap-4">
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
          {tabs.map((tab, index) => {
            const normalizedSegment = normalizeSegment(tab.segment);
            const href = getTabPath(normalizedBasePath, tab.segment);
            const isSelected =
              normalizedSegment === ``
                ? pathname === normalizedBasePath
                : pathname === href ||
                  pathname.startsWith(`${href}/`) ||
                  (!hasBasePathTab && index === 0 && pathname === normalizedBasePath);

            return (
              <Link
                key={`${tab.segment}-${tab.label}`}
                to={href}
                className={cx(
                  `flex shrink-0 justify-center rounded-lg border px-3 py-1 text-center whitespace-nowrap outline-none transition-[background-color,border-color,box-shadow,color] duration-100 select-none @sm/main:flex-grow`,
                  isSelected
                    ? `border-stone-200 bg-white text-stone-900 shadow shadow-stone-300/30`
                    : `border-transparent text-stone-600 hover:bg-stone-200/50 focus-visible:bg-stone-200/50`,
                )}
                aria-current={isSelected ? `page` : undefined}
              >
                <span className="inline-flex items-center gap-2">
                  <span>{tab.label}</span>
                  {tab.badgeCount !== undefined && (
                    <span
                      className={cx(
                        `min-w-5 rounded-full px-1.5 py-0.25 text-xs font-medium tabular-nums`,
                        isSelected
                          ? `bg-stone-100 text-stone-700`
                          : `bg-stone-200/70 text-stone-600`,
                      )}
                    >
                      {tab.badgeCount}
                    </span>
                  )}
                </span>
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
      <Outlet />
    </div>
  );
};

export default SegmentedTabs;
