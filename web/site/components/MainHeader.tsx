import React from 'react';
import cx from 'classnames';
import Link from 'next/link';
import { Logo } from '@shared/components';
import FancyLink from './FancyLink';
import MobileLoginDropdown from './MobileLoginDropdown';

const MainHeader: React.FC = () => (
  <header
    className={cx(
      `flex justify-between items-center px-8 transition-[background-color,padding,margin,border-radius,box-shadow] duration-500 top-0 left-0 right-0 z-50 py-6 relative`,
    )}
  >
    <Link href="/">
      <Logo className={cx(`transition-opacity duration-500`)} type="inverted" />
    </Link>
    <MobileLoginDropdown />
    <div className={cx(`gap-4 transition-opacity duration-500 hidden sm:flex`)}>
      <FancyLink href="https://parents.gertrude.app" size="sm" color="secondary" inverted>
        Log in
      </FancyLink>
      <FancyLink
        href="https://parents.gertrude.app/signup"
        size="sm"
        color="primary"
        inverted
      >
        Sign up
      </FancyLink>
    </div>
  </header>
);

export default MainHeader;
