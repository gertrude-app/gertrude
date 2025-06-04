import { Logo } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import FancyLink from './FancyLink';
import MobileLoginDropdown from './MobileLoginDropdown';

const MainHeader: React.FC<{ theme: `violet` | `white` }> = ({ theme }) => (
  <header
    className={cx(
      `flex justify-between items-center px-6 xs:px-8 top-0 left-0 right-0 z-50 py-6 relative`,
    )}
  >
    <a href="/">
      <Logo
        className={cx(`transition-opacity duration-500`)}
        type={theme === `violet` ? `inverted` : `default`}
      />
    </a>
    <MobileLoginDropdown theme={theme} />
    <div className={cx(`gap-4 transition-opacity duration-500 hidden sm:flex`)}>
      <FancyLink
        type="link"
        href="https://parents.gertrude.app"
        size="sm"
        color="secondary"
        inverted={theme === `violet`}
      >
        Log in
      </FancyLink>
      <FancyLink
        type="link"
        href="https://parents.gertrude.app/signup?v=new_site"
        size="sm"
        color="primary"
        inverted={theme === `violet`}
      >
        Sign up
      </FancyLink>
    </div>
  </header>
);

export default MainHeader;
