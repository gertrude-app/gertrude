import React from 'react';
import { Link, Outlet, useLocation } from '@tanstack/react-router';
import cx from 'clsx';

interface Tab {
  label: string;
  segment: string;
}

interface Props {
  basePath: string;
  tabs: Tab[];
  className?: string;
}

const normalizePath = (path: string): string => {
  const withLeadingSlash = path.startsWith('/') ? path : `/${path}`;
  return withLeadingSlash === '/'
    ? withLeadingSlash
    : withLeadingSlash.replace(/\/+$/, '');
};

const normalizeSegment = (segment: string): string => {
  return segment.replace(/^\/+|\/+$/g, '');
};

const getTabPath = (basePath: string, segment: string): string => {
  const normalizedBasePath = normalizePath(basePath);
  const normalizedSegment = normalizeSegment(segment);

  if (!normalizedSegment) {
    return normalizedBasePath;
  }

  return normalizedBasePath === '/'
    ? `/${normalizedSegment}`
    : `${normalizedBasePath}/${normalizedSegment}`;
};

const SegmentedTabs: React.FC<Props> = ({ basePath, tabs, className }) => {
  const { pathname } = useLocation();
  const normalizedBasePath = normalizePath(basePath);

  return (
    <div className="flex flex-col gap-4">
      <nav className={cx('flex rounded-xl bg-stone-100 p-1.5', className)}>
        {tabs.map((tab, index) => {
          const href = getTabPath(normalizedBasePath, tab.segment);
          const isSelected =
            pathname === href ||
            pathname.startsWith(`${href}/`) ||
            (index === 0 && pathname === normalizedBasePath);

          return (
            <Link
              key={`${tab.segment}-${tab.label}`}
              to={href}
              className={cx(
                'flex flex-grow justify-center rounded-lg border p-1 text-center outline-none transition-[background-color,border-color,box-shadow,color] duration-100 select-none',
                isSelected
                  ? 'border-stone-200 bg-white text-stone-900 shadow shadow-stone-300/30'
                  : 'border-transparent text-stone-600 hover:bg-stone-200/50 focus-visible:bg-stone-200/50',
              )}
              aria-current={isSelected ? 'page' : undefined}
            >
              {tab.label}
            </Link>
          );
        })}
      </nav>
      <Outlet />
    </div>
  );
};

export default SegmentedTabs;
