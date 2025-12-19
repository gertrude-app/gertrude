import { Bars3Icon } from '@heroicons/react/24/solid';
import { Logo } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import { Link } from 'react-router-dom';

interface MobileStickyHeaderProps {
  className?: string;
  sidebarShown: boolean;
  onHamburgerClick(): unknown;
}

const MobileStickyHeader: React.FC<MobileStickyHeaderProps> = ({
  onHamburgerClick,
  sidebarShown,
  className,
}) => (
  <header
    className={cx(
      `h-[64px] sm:h-[72px] top-0 justify-between items-center px-1 sm:px-2 z-30 bg-slate-900 flex shadow-md shadow-slate-300/20`,
      className,
    )}
  >
    <button
      type="button"
      className="px-3 py-2 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/40 rounded-md"
      onClick={onHamburgerClick}
    >
      <span className="sr-only">Open sidebar</span>
      <Bars3Icon className="h-9 text-slate-500 text-opacity-70 hover:text-opacity-90 transition-[text-opacity] duration-100 cursor-pointer" />
    </button>
    <Link
      to="/"
      className={cx(
        `px-2 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/40 rounded-md transition-opacity`,
        sidebarShown ? `opacity-0` : `opacity-100`,
      )}
    >
      <Logo
        className="scale-75 sm:scale-90 antialiased"
        withForParents="condensed"
        type="inverted"
      />
    </Link>
    <div className="px-3 py-2 opacity-0">
      <i className="fa fa-bars text-3xl text-white" aria-hidden="true" />
    </div>
  </header>
);

export default MobileStickyHeader;
