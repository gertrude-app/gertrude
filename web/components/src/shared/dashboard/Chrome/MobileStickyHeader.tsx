import React from 'react';
import cx from 'classnames';
import { Link } from 'react-router-dom';
import Logo from '../../Logo';

interface MobileStickyHeaderProps {
  sidebarShown: boolean;
  onHamburgerClick(): unknown;
}

const MobileStickyHeader: React.FC<MobileStickyHeaderProps> = ({
  onHamburgerClick,
  sidebarShown,
}) => (
  <header className="h-16 sticky top-0 justify-between items-center px-1 py-4 shadow z-20 bg-gray-900 bg-gradient-to-b from-transparent via-transparent to-violet-900/70 md:hidden flex">
    <button
      type="button"
      className="px-3 py-2 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/40 rounded-md"
      onClick={onHamburgerClick}
    >
      <span className="sr-only">Open sidebar</span>
      <i
        className="fa fa-bars text-3xl text-white text-opacity-70 hover:text-opacity-90 transition duration-100 cursor-pointer"
        aria-hidden="true"
      />
    </button>
    <Link
      to="/"
      className={cx(
        `px-3 py-2 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/40 rounded-md transition-opacity`,
        sidebarShown ? `opacity-0` : `opacity-100`,
      )}
    >
      <Logo type="on-dark" className="scale-75 sm:scale-90 opacity-90 antialiased" />
    </Link>
    <div className="px-3 py-2 opacity-0">
      <i className="fa fa-bars text-3xl text-white" aria-hidden="true" />
    </div>
  </header>
);

export default MobileStickyHeader;
